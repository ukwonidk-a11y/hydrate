local DynamicList = require(script.Parent.DynamicList)

local Values = {}

function Values.new(input, transform)
	return DynamicList.new(input, function(valueSource, indexSource, presentSource)
		return transform(valueSource(), indexSource, presentSource)
	end, function(_, value)
		return value
	end, function(entry, index)
		if entry.indexSource() ~= index then
			entry.indexSource(index)
		end
	end)
end

return Values
