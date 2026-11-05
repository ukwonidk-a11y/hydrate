local Ownership = {}

local owners = setmetatable({}, { __mode = "k" })

export type Owner = {
	destroy: () -> (),
}

function Ownership.register(instance: Instance, owner: Owner)
	owners[instance] = owner
end

function Ownership.destroy(instance: Instance)
	local owner = owners[instance]

	if owner then
		owners[instance] = nil
		owner.destroy()
	end
end

function Ownership.adopt(instance: Instance, scope)
	local owner = owners[instance]

	if owner then
		scope:addCleanup(function()
			Ownership.destroy(instance)
		end)
	end
end

return Ownership
