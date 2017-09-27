--- Wrapper module for io.open and io.write
-- Files will be saved in a path created from a call to sys.get_save_file() with
-- application id equal to the game.project config project.title with spaces
-- replaced with underscores.
-- @usage
-- local savefile = require "ludobits.m.savefile"
--
-- local file = savefile.open("foobar")
-- local data = file.load()
-- file.save("something large to save")
--

local file = require "ludobits.m.file"

local M = {}

function M.get_path(filename)
	local path = sys.get_save_file(file.fix(sys.get_config("project.title"):gsub(" ", "_")), filename)
	return path
end

--- Open a file for reading and writing using the io.* functions
-- @param filename
-- @return file instance
function M.open(filename)
	local path = M.get_path(filename)
	local instance = {}
	
	--- Load the table stored in the file
	-- @return contents File contents or nil if something went wrong
	-- @return error_message Error message if something went wrong while reading
	function instance.load()
		local f, err = io.open(path, "rb")
		if err then
			return nil, err
		end
		return f:read("*a")
	end
	
	--- Save string to the file
	-- @param s The string to save
	-- @return success
	-- @return error_message
	function instance.save(s)
		assert(s and type(s) == "string", "You must provide a string to save")
		local f, err = io.open(path, "wb")
		if err then
			return nil, err
		end
		f:write(s)
		return true
	end
	
	return instance
end



return M