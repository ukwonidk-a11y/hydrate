local Packages = script.Parent.Parent.Parent

local Charm = require(Packages.Charm)
local Scope = require(script.Parent.Parent.core.Scope)
local Branch = require(script.Parent.Branch)

local untracked = Charm.untracked

local Switch = {}

Switch.KIND = {}

export type Component = (present: Charm.Atom<boolean>) -> (any, number?)

type BranchRecord = {
	destroy: () -> (),
	object: any,
	delay: number,
	present: Charm.Atom<boolean>,
	timeout: thread?,
}

function Switch.new(input: () -> any, map: { [any]: Component })
	local outputSource = Charm.atom(nil)

	local branches: { [any]: BranchRecord } = {}

	local function updateOutput()
		local output = table.create(4)

		untracked(function()
			for _, branch in branches do
				table.insert(output, branch.object)
			end
		end)

		if #output == 0 then
			outputSource(nil)
		elseif #output == 1 then
			outputSource(output[1])
		else
			outputSource(output)
		end
	end

	local scope = Scope.new(function(scope)
		Charm.listen(input, function(key)
			-- Destroy or queue destruction for every inactive branch.
			for branchKey, branch in branches do
				if branchKey ~= key then
					branch.present(false)

					if branch.timeout == nil then
						branch.timeout = task.delay(branch.delay, function()
							branch.timeout = nil

							if branches[branchKey] == branch and not branch.present() then
								branch.destroy()
								branches[branchKey] = nil
								updateOutput()
							end
						end)
					end
				end
			end

			-- Restore an existing branch or create a new one.
			if key ~= nil then
				local branch = branches[key]

				if branch then
					if branch.timeout then
						task.cancel(branch.timeout)
						branch.timeout = nil
					end

					branch.present(true)
				else
					local component = map[key]

					if component ~= nil then
						assert(type(component) == "function", "Hydrate.switch map values must be functions")

						local present = Charm.atom(false)

						local delay

						local destroy, object

						destroy, object = Branch.new(scope, function()
							local result, componentDelay = component(present)
							delay = componentDelay
							return result
						end)

						present(true)

						branches[key] = {
							destroy = destroy,
							object = object,
							delay = delay or 0,
							present = present,
							timeout = nil,
						}
					end
				end
			end

			updateOutput()
		end)

		scope:addCleanup(function()
			for key, branch in branches do
				if branch.timeout then
					task.cancel(branch.timeout)
					branch.timeout = nil
				end

				branch.destroy()
				branches[key] = nil
			end
		end)
	end)

	return {
		kind = Switch.KIND,
		get = outputSource,
		scope = scope,
	}
end

return Switch
