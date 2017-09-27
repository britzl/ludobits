--- Wrapper module for sys.load() and sys.save()
-- Files will be saved in a path created from a call to sys.get_save_file() with
-- application id equal to the game.project config project.title with spaces
-- replaced with underscores.
--
-- @usage
-- local savetable = require "ludobits.m.savetable"
--
-- local file = savetable.open("foobar")
-- local data = file.load()
-- file.save({ foo = "bar" })
--

local file = require "ludobits.m.file"

local M = {}

function M.get_path(filename)
	local path = sys.get_save_file(file.fix(sys.get_config("project.title"):gsub(" ", "_")), filename)
	return path
end

--- Open a file for reading and writing using sys.save and sys.load
-- @param filename
-- @return file instance
function M.open(filename)
	local path = M.get_path(filename)
	local instance = {}
	
	--- Load the table stored in the file
	-- @return File contents
	function instance.load()
		return sys.load(path)
	end
	
	--- Save table to the file
	-- @param t The table to save
	-- @return success
	-- @return error_message
	function instance.save(t)
		assert(t and type(t) == "table", "You must provide a table to save")
		local success = sys.save(path, t)
		if not success then
			return false, "Unable to save file"
		end
		return true
	end
	
	return instance
end



return M