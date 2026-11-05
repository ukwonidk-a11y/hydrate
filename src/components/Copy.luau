local Apply = require(script.Parent.Parent.core.Apply)
local Scope = require(script.Parent.Parent.core.Scope)
local Ownership = require(script.Parent.Parent.core.Ownership)

local Copy = {}

function Copy.new(template: Instance)
	return function(properties)
		local instance = template:Clone()

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

return Copy
