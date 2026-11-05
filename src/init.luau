local Node = require(script.components.Node)
local Copy = require(script.components.Copy)
local Create = require(script.components.Create)

local Indexes = require(script.dynamic.Indexes)
local Values = require(script.dynamic.Values)

local Show = require(script.dynamic.Show)
local Switch = require(script.dynamic.Switch)

local Scope = require(script.core.Scope)

local function mount(component, parent)
	local result

	local scope = Scope.new(function()
		result = component()

		if typeof(result) == "Instance" then
			result.Parent = parent
		end
	end)

	return function()
		scope:destroy()
	end
end

return {
	node = Node.new,
	copy = Copy.new,
	create = Create.new,

	indexes = Indexes.new,
	values = Values.new,

	show = Show.new,
	switch = Switch.new,

	mount = mount,
	scope = function(cb)
		local s = Scope.new(cb)
		return function()
			s:destroy()
		end
	end,
}
