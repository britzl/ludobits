--- Save and load tables, either using io.* or sys.*
--
-- @usage
-- local savetable = require "ludobits.m.io.savetable"
--
-- local data = savetable.load("foobar", savetable.FORMAT_IO)
-- data.foo = "bar"
-- savetable.save(data)
--
-- local data = savetable.load("foobar")
-- print(data.foo) --> "bar"

local savefile = require "ludobits.m.io.savefile"
local file = require "ludobits.m.io.file"
local json = require "ludobits.m.json"

local M = {}

M.FORMAT_IO = "io"
M.FORMAT_SYS = "sys"



local function load(path, format)
	if format == M.FORMAT_IO then
		local f, err = io.open(path, "rb")
		if err then
			return nil, err
		end
		local s = f:read("*a")
		if not s then
			return nil
		end
		return json.decode(s)
	elseif format == M.FORMAT_SYS then
		return sys.load(path)
	end
end


local function save(data, path, format)
	if format == M.FORMAT_IO then
		local s = json.encode(data)
		if not s then
			return false
		end
		local f, err = io.open(path, "wb")
		if err then
			return nil, err
		end
		f:write(s)
		f:flush()
		f:close()
		return true
	elseif format == M.FORMAT_SYS then
		return sys.save(path, data)
	end
end


function M.load(filename, format)
	assert(filename, "You must provide a filename")
	format = format or M.FORMAT_SYS
	assert(format == M.FORMAT_IO or format == M.FORMAT_SYS, "Unknown format")

	local path = file.get_save_file_path(filename)
	local data = load(path, format)
	data = data or {}

	local mt = {}
	mt.path = path
	mt.format = format

	return setmetatable(data, mt)
end


function M.save(data, filename, format)
	assert(data, "You must provide some data to save")
	local mt = getmetatable(data)
	if not mt then
		assert(filename, "You must provide a filename")
		local path = file.get_save_file_path(filename)
		format = format or M.FORMAT_SYS
		mt = {}
		mt.path = path
		mt.format = format
	else
		if filename then
			local path = file.get_save_file_path(filename)
			mt.path = path
		end
		if format then
			mt.format = format
		end
	end
	setmetatable(data, mt)
	return save(data, mt.path, mt.format)
end






function M.open(filename)
	print("savetable.open() is deprecated. Use savetable.load() and save() instead")
	local instance = {}
	function instance.load()
		local ok, t_or_err = pcall(function()
			local s, err = file.load()
			if err then
				return nil
			end
			return json.decode(s)
		end)
		return ok and t_or_err, not ok and t_or_err
	end
	function instance.save(t)
		assert(t and type(t) == "table", "You must provide a table to save")
		return pcall(function()
			local s = json.encode(t)
			return file.save(s)
		end)
	end
	return instance
end


return M
