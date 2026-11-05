local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Charm = require(Packages.Charm)

local Scope = {}

local scopeStack = {}

export type Scope = {
	destroy: (self: Scope) -> (),
	addCleanup: (self: Scope, cleanup: () -> ()) -> (),
	addScope: (self: Scope, childScope: Scope) -> (),
}

function Scope.new(callback: (scope: Scope) -> (), detached: boolean?): Scope
	local cleanups = {}
	local destroyed = false

	local self = {}

	function self:addCleanup(cleanup)
		if destroyed then
			cleanup()
			return
		end

		table.insert(cleanups, cleanup)
	end

	function self:addScope(childScope: Scope)
		self:addCleanup(function()
			childScope:destroy()
		end)
	end

	local dispose

	function self:destroy()
		if destroyed then
			return
		end

		destroyed = true

		if dispose then
			dispose()
		end
	end

	Scope.push(self)

	dispose = Charm.effectScope(function()
		local ok, err = xpcall(function()
			callback(self)
		end, debug.traceback)

		if not ok then
			error(err, 0)
		end

		return function()
			for i = #cleanups, 1, -1 do
				cleanups[i]()
			end

			table.clear(cleanups)
		end
	end, detached)

	Scope.pop()

	return self
end

function Scope.push(scope: Scope)
	table.insert(scopeStack, scope)
end

function Scope.pop()
	table.remove(scopeStack)
end

function Scope.current(): Scope?
	return scopeStack[#scopeStack]
end

return Scope
