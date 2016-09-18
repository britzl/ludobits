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

local M = {}


local function get_path(filename)
	local path = sys.get_save_file(sys.get_config("project.title"):gsub(" ", "_"), filename)
	return path
end

--- Open a file
-- @param filename
-- @return file instance
function M.open(filename)
	local path = get_path(filename)
	local instance = {}
	
	--- Load the contents of the file
	-- @return File contents
	function instance.load()
		return sys.load(path)
	end
	
	--- Save table to the file
	-- @param t The table to save
	-- @return success
	function instance.save(t)
		assert(t and type(t) == "table", "You must provide a table to save")
		local tmpfile = get_path("____tmp")
		-- write to temp file first, then move it
		return pcall(function()
			sys.save(tmpfile, t)
			os.remove(path)
			os.rename(tmpfile, path)
		end)
	end
	
	return instance
end



return M