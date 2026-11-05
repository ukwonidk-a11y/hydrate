local Packages = script.Parent.Parent.Parent

local Charm = require(Packages.Charm)
local Declaration = require(script.Parent.Parent.core.Declaration)
local Scope = require(script.Parent.Parent.core.Scope)
local Ownership = require(script.Parent.Parent.core.Ownership)
local DynamicList = require(script.Parent.Parent.dynamic.DynamicList)
local Switch = require(script.Parent.Parent.dynamic.Switch)

local Apply

local function applyProperty(instance: Instance, property: string, value: any, scope)
	if type(value) == "function" then
		local currentValue = (instance :: any)[property]

		if typeof(currentValue) == "RBXScriptSignal" then
			local connection = currentValue:Connect(value)

			scope:addCleanup(function()
				connection:Disconnect()
			end)
		else
			Charm.effect(function()
				(instance :: any)[property] = value()
			end)
		end
	else
		(instance :: any)[property] = value
	end
end

local function applyChild(instance: Instance, value: any, childScope)
	if typeof(value) == "Instance" then
		value.Parent = instance

		childScope:addCleanup(function()
			if value.Parent == instance then
				value.Parent = nil
			end
		end)

		Ownership.adopt(value, childScope)
	elseif type(value) == "table" and value.kind == Declaration.NODE then
		local child = Declaration.resolveNode(instance, value)

		child.Parent = instance

		Apply(child, value.properties, childScope)

		childScope:addCleanup(function()
			if child.Parent == instance then
				child.Parent = nil
			end
		end)
	end
end

local function applyChildren(instance: Instance, create: () -> any, scope)
	local currentScope

	Charm.effect(function()
		local value = create()

		if currentScope then
			currentScope:destroy()
			currentScope = nil
		end

		if value == nil then
			return
		end

		currentScope = Scope.new(function(childScope)
			if type(value) == "table" and value.kind == nil then
				for _, child in value do
					applyChild(instance, child, childScope)
				end
			else
				applyChild(instance, value, childScope)
			end
		end, true)
	end)

	scope:addCleanup(function()
		if currentScope then
			currentScope:destroy()
		end
	end)
end

local function applyDynamicList(instance, list, scope)
	local currentChildren = {}

	Charm.effect(function()
		local children = list.get()
		local newChildren = {}

		for _, child in children do
			newChildren[child] = true
		end

		for _, child in currentChildren do
			if not newChildren[child] then
				if child.Parent == instance then
					child.Parent = nil
				end
			end
		end

		for _, child in children do
			child.Parent = instance
		end

		currentChildren = children
	end)

	scope:addCleanup(function()
		for _, child in currentChildren do
			if child.Parent == instance then
				child.Parent = nil
			end
		end

		list.scope:destroy()
	end)
end

local function applyBranch(instance, branch, scope)
	local currentChildren = {}

	Charm.effect(function()
		local value = branch.get()
		local children = {}

		if value ~= nil then
			if type(value) == "table" and value.kind == nil then
				children = value
			else
				children = { value }
			end
		end

		local nextChildren = {}

		for _, child in children do
			nextChildren[child] = true
		end

		-- Remove children that are no longer present.
		for child, childScope in currentChildren do
			if not nextChildren[child] then
				childScope:destroy()
				currentChildren[child] = nil
			end
		end

		-- Mount only newly introduced children.
		for _, child in children do
			if currentChildren[child] == nil then
				currentChildren[child] = Scope.new(function(childScope)
					applyChild(instance, child, childScope)
				end, true)
			end
		end
	end)

	scope:addCleanup(function()
		for _, childScope in currentChildren do
			childScope:destroy()
		end

		table.clear(currentChildren)
		branch.scope:destroy()
	end)
end

local function processProperties(instance: Instance, properties: { [any]: any }, scope)
	local parentValue

	for property, value in properties do
		if type(property) == "string" then
			if property == "Parent" then
				parentValue = value
			else
				applyProperty(instance, property, value, scope)
			end
		elseif type(property) == "number" then
			if type(value) == "function" then
				applyChildren(instance, value, scope)
			elseif type(value) == "table" then
				if value.kind == DynamicList.KIND then
					applyDynamicList(instance, value, scope)
				elseif value.kind == Switch.KIND then
					applyBranch(instance, value, scope)
				elseif value.kind == Declaration.NODE then
					local childScope = Scope.new(function(childScope)
						applyChild(instance, value, childScope)
					end, true)

					scope:addCleanup(function()
						childScope:destroy()
					end)
				end
			elseif typeof(value) == "Instance" then
				value.Parent = instance
				Ownership.adopt(value, scope)
			end
		end
	end

	if parentValue ~= nil then
		applyProperty(instance, "Parent", parentValue, scope)
	end
end

function Apply(instance: Instance, properties: { [any]: any }, scope)
	assert(properties, "Hydrate node requires a properties table")

	processProperties(instance, properties, scope)

	return instance
end

return Apply
