--- Simple Lua logger

local M = {}

M.DEBUG = 1
M.INFO = 2
M.WARN = 3
M.ERROR = 4
M.FATAL = 5
M.NONE = 6

local function silent() end

local debug = _G.print
local info = _G.print
local warn = _G.print
local error = _G.print
local fatal = _G.print

--- Set the current accepted log level. Any logger calls with a level less than
-- this will be silenced
-- @param level The minimum accepted level
function M.level(level)
	debug = level > M.DEBUG and silent or _G.print
	info = level > M.INFO and silent or _G.print
	warn = level > M.WARN and silent or _G.print
	error = level > M.ERROR and silent or _G.print
	fatal = level > M.FATAL and silent or _G.print
end

--- Create a logger instance
-- @param tag Optional tag to prepend to all log output
-- @return Logger instance
function M.create(tag)
	tag = tag or ""

	local instance = {}

	--- Log with level set to DEBUG
	function instance.debug(...) debug("DEBUG", tag, ...) end
	--- Log with level set to INFO
	function instance.info(...) info("INFO", tag, ...) end
	--- Log with level set to WARN
	function instance.warn(...) warn("WARN", tag, ...) end
	--- Log with level set to ERROR
	function instance.error(...) error("ERROR", tag, ...) end
	--- Log with level set to FATAL
	function instance.fatal(...) fatal("FATAL", tag, ...) end
	--- Log with level set to DEBUG
	function instance.d(...) debug("DEBUG", tag, ...) end
	--- Log with level set to INFO
	function instance.i(...) info("INFO", tag, ...) end
	--- Log with level set to WARN
	function instance.w(...) warn("WARN", tag, ...) end
	--- Log with level set to ERROR
	function instance.e(...) error("ERROR", tag, ...) end
	--- Log with level set to FATAL
	function instance.f(...) fatal("FATAL", tag, ...) end

	setmetatable(instance, {
		__call = function(t, ...)
			return instance.debug(...)
		end
	})
	return instance
end



return M
