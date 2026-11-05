local Apply = require(script.Parent.Parent.core.Apply)
local Scope = require(script.Parent.Parent.core.Scope)
local Declaration = require(script.Parent.Parent.core.Declaration)

local Node = {}

local NODE = {}

function Node.new(target: Instance | string)
	return function(properties)
		if typeof(target) == "Instance" then
			local parentScope = Scope.current()

			local scope = Scope.new(function(scope)
				Apply(target, properties, scope)
			end, true)

			if parentScope then
				parentScope:addScope(scope)
			end

			return target
		end

		return Declaration.node(target, properties)
	end
end

Node.NODE = NODE

return Node
