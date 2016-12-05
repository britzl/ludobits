--- Wrapper module for sys.load() and sys.save()
-- Files will be saved in a path created from a call to sys.get_save_file() with
-- application id equal to the game.project config project.title with spaces
-- replaced with underscores.
-- @usage
-- local savefile = require "ludobits.m.savefile"
--
-- local file = savefile.open("foobar")
-- local data = file.load()
-- file.save({ foo = "bar" })
--

local M = {
	tmpname = "___lbtmp"
}

function M.get_path(filename)
	local path = sys.get_save_file(sys.get_config("project.title"):gsub(" ", "_"), filename)
	return path
end

--- Open a file
-- @param filename
-- @return file instance
function M.open(filename)
	local path = M.get_path(filename)
	local instance = {}
	
	--- Load the contents of the file
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
		--local tmpname = ((sys.get_sys_info().system_name == "Windows") and os.getenv("TMP") or "") .. os.tmpname()
		-- os.tmpname() is not very reliable on windows (it doesn't return a valid path to a temp file)
		-- it's better to return the path to an application local file, and in this case we use the same filename
		-- every time so that we do not pollute the filesystem with many temporary files in case of problems
		-- when writing to the file
		-- it is reasonable to assume that a filename such as "___lbtmp" isn't used by any other part of the
		-- system, and if that is actually the case it is possible to change it
		local tmpname = M.get_path(M.tmpname)
		local success = sys.save(tmpname, t)
		if not success then
			return false, "Unable to save file"
		end
		os.remove(path)
		return os.rename(tmpname, path)
	end
	
	return instance
end



return M