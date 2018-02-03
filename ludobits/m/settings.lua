local savetable = require "ludobits.m.io.savetable"

local M = {}

local settings = savetable.open("__settings").load() or {}

--- Save settings to disk. The settings will be saved to a file named __settings
function M.save()
	savetable.open("__settings").save(settings)
end

local mt = {}
function mt.__index(t, k)
	return settings[k]
end
function mt.__newindex(t, k, v)
	settings[k] = v
end


return setmetatable(M, mt)
