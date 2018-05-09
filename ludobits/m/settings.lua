local savetable = require "ludobits.m.io.savetable"

local M = {}

local settings_filename
local settings

--- Load settings from disk
-- @param filename File to load from or nil for the default file ("__settings")
function M.load(filename)
	settings_filename = filename or "__settings"
	settings = savetable.open(settings_filename).load() or {}
end

--- Get the filename of the currently loaded settings file
-- @return Filename
function M.filename()
	return settings_filename
end

--- Check if the settings are empty
-- @return true if empty
function M.is_empty()
	return next(settings) == nil
end

--- Save settings to disk
-- @param filename File to save to or nil for the currently loaded file
function M.save(filename)
	settings_filename = filename or settings_filename
	savetable.open(settings_filename).save(settings)
end

M.load()

local mt = {}
function mt.__index(t, k)
	return settings[k]
end
function mt.__newindex(t, k, v)
	settings[k] = v
end


return setmetatable(M, mt)
