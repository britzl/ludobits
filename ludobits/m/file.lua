

local M = {}

function M.fix(filename)
	filename = filename:gsub("\n", "\r\n")
	filename = filename:gsub("([^0-9a-zA-Z ])", function(c) string.format("%%%02X", string.byte(c)) end)
	filename = filename:gsub(" ", "+")
	return filename
end

return M