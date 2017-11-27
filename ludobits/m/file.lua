--- File manipulation utilities

local M = {}

--- Fix a filename to ensure that it doesn't contain any illegal characters
-- @param filename
-- @return Filename with illegal characters replaced
function M.fix(filename)
	filename = filename:gsub("([^0-9a-zA-Z%._ ])", function(c) return string.format("%%%02X", string.byte(c)) end)
	filename = filename:gsub(" ", "+")
	return filename
end

--- Get an application specific save file path to a filename. The path will be
-- based on the sys.get_save_file() function and the project title (with whitespace)
-- replaced by underscore
-- @param filename
-- @return Save file path
function M.get_save_file_path(filename)
	local path = sys.get_save_file(M.fix(sys.get_config("project.title"):gsub(" ", "_")), filename)
	return path
end

return M
