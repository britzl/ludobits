--- Wrapper module for io.open and io.write
-- Files will be saved in a path created from a call to sys.get_save_file() with
-- application id equal to the game.project config project.title with invalid path
-- characters replaced.
-- @usage
-- local savefile = require "ludobits.m.io.savefile"
--
-- local file = savefile.open("foobar")
-- local data = file.load()
-- file.save("something large to save")
--

local file = require "ludobits.m.io.file"

local M = {}

--- Open a file for reading and writing using the io.* functions
-- @param filename
-- @return file instance
function M.open(filename)
	local path = file.get_save_file_path(filename)
	local instance = {}

	--- Load the table stored in the file
	-- @param mode The read mode, defaults to "rb"
	-- @return contents File contents or nil if something went wrong
	-- @return error_message Error message if something went wrong while reading
	function instance.load(mode)
		local f, err = io.open(path, mode or "rb")
		if err then
			return nil, err
		end
		return f:read("*a")
	end

	--- Save string to the file
	-- @param s The string to save
	-- @param mode The write mode, defaults to "wb"
	-- @return success
	-- @return error_message
	function instance.save(s, mode)
		assert(s and type(s) == "string", "You must provide a string to save")
		local f, err = io.open(path, mode or "wb")
		if err then
			return nil, err
		end
		f:write(s)
		f:flush()
		f:close()
		return true
	end

	return instance
end



return M
