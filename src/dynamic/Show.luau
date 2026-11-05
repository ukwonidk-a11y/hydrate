local Switch = require(script.Parent.Switch)

local Show = {}

function Show.new(input: () -> any, component)
	return Switch.new(function()
		return not not input()
	end, {
		[true] = component,
	})
end

return Show
