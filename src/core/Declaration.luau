local Declaration = {}

local NODE = {}
local CLONE = {}

local resolvedNodes = setmetatable({}, {
	__mode = "k",
})

function Declaration.node(target, properties)
	return {
		kind = NODE,
		target = target,
		properties = properties,
	}
end

function Declaration.clone(template, properties)
	return {
		kind = CLONE,
		template = template,
		properties = properties,
	}
end

function Declaration.resolveNode(parent: Instance, declaration): Instance
	local nodes = resolvedNodes[parent]

	if nodes == nil then
		nodes = {}
		resolvedNodes[parent] = nodes
	end

	local child = nodes[declaration.target]

	if child == nil then
		child = parent:WaitForChild(declaration.target, 5)

		assert(child, `Hydrate.node("{declaration.target}") could not find child of {parent:GetFullName()}`)

		nodes[declaration.target] = child
	end

	return child
end

Declaration.NODE = NODE
Declaration.CLONE = CLONE

return Declaration
