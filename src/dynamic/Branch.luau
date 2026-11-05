local Scope = require(script.Parent.Parent.core.Scope)

local Branch = {}

function Branch.new(ownerScope, callback)
	local result

	local scope = Scope.new(function()
		local ok, value = xpcall(callback, debug.traceback)

		if not ok then
			error(`error while running branch():\n\n{value}`, 0)
		end

		result = value
	end, true)

	ownerScope:addScope(scope)

	return function()
		scope:destroy()
	end, result
end

return Branch
