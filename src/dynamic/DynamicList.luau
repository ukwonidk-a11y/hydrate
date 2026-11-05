local Packages = script.Parent.Parent.Parent

local Charm = require(Packages.Charm)
local Scope = require(script.Parent.Parent.core.Scope)

local DynamicList = {}

export type Entry = {
	scope: Scope.Scope,
	value: any,
	valueSource: Charm.Atom<any>,
	indexSource: Charm.Atom<any>,
	presentSource: Charm.Atom<boolean>,
	result: any,
	count: number,
	delay: number,
	timeout: thread?,
}

export type Transform = (
	valueSource: Charm.Atom<any>,
	indexSource: Charm.Atom<any>,
	presentSource: Charm.Atom<boolean>
) -> (any, number?)

DynamicList.KIND = {}

function DynamicList.new(
	input: () -> { [any]: any },
	transform: Transform,
	keyFrom: (index: any, value: any) -> any,
	update: (entry: Entry, index: any, value: any) -> ()
)
	local updateCount = 0
	local entries: { [any]: Entry } = {}
	local outputSource = Charm.atom({})

	local function updateOutput()
		local output = table.create(4)

		for _, entry in entries do
			table.insert(output, entry.result)
		end

		outputSource(output)
	end

	local scope = Scope.new(function(scope)
		Charm.effect(function()
			local values = input()

			local count = updateCount
			updateCount += 1

			local childrenNeedUpdate = false

			for index, value in values do
				local key = keyFrom(index, value)
				local entry = entries[key]

				if entry == nil then
					local valueSource = Charm.atom(value)
					local indexSource = Charm.atom(index)
					local presentSource = Charm.atom(false)

					local result
					local delay

					local childScope = Scope.new(function()
						result, delay = transform(valueSource, indexSource, presentSource)
					end, true)

					presentSource(true)

					entry = {
						scope = childScope,
						value = value,
						valueSource = valueSource,
						indexSource = indexSource,
						presentSource = presentSource,
						result = result,
						count = count,
						delay = delay or 0,
						timeout = nil,
					}

					entries[key] = entry
					childrenNeedUpdate = true
				else
					entry.count = count

					if entry.timeout then
						task.cancel(entry.timeout)
						entry.timeout = nil
						entry.presentSource(true)
					end

					update(entry, index, value)
				end
			end

			for key, entry in entries do
				if entry.count < count then
					entry.presentSource(false)

					if entry.delay == 0 then
						entry.scope:destroy()
						entries[key] = nil
						childrenNeedUpdate = true
					elseif entry.timeout == nil then
						entry.value = nil

						entry.timeout = task.delay(entry.delay, function()
							entry.timeout = nil

							entry.scope:destroy()
							entries[key] = nil

							updateOutput()
						end)
					end
				end
			end

			if childrenNeedUpdate then
				updateOutput()
			end
		end)

		scope:addCleanup(function()
			for key, entry in entries do
				if entry.timeout then
					task.cancel(entry.timeout)
					entry.timeout = nil
				end

				entry.scope:destroy()
				entries[key] = nil
			end
		end)
	end)

	return {
		kind = DynamicList.KIND,
		get = outputSource,
		scope = scope,
	}
end

return DynamicList
