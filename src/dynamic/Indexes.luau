local DynamicList = require(script.Parent.DynamicList)

local Indexes = {}

function Indexes.new(input, transform)
	return DynamicList.new(input, function(valueSource, indexSource, presentSource)
		return transform(valueSource, indexSource(), presentSource)
	end, function(index)
		return index
	end, function(entry, _, value)
		if entry.value ~= value then
			entry.value = value
			entry.valueSource(value)
		end
	end)
end

return Indexes
