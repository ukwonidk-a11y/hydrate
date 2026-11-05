local Apply = require(script.Parent.Parent.core.Apply)
local Scope = require(script.Parent.Parent.core.Scope)
local Ownership = require(script.Parent.Parent.core.Ownership)

local Create = {}

function Create.new(className: string)
	return function(properties)
		local instance = Instance.new(className)

		local scope = Scope.new(function(scope)
			scope:addCleanup(function()
				instance:Destroy()
			end)

			Apply(instance, properties, scope)
		end)

		Ownership.register(instance, scope)

		return instance
	end
end

return Create
