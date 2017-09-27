

local M = {}

function M.fix(filename)
	filename = filename:gsub("([^0-9a-zA-Z%._ ])", function(c) return string.format("%%%02X", string.byte(c)) end)
	filename = filename:gsub(" ", "+")
	return filename
end

return M