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

function M.level(level)
	debug = level > M.DEBUG and silent or _G.print
	info = level > M.INFO and silent or _G.print
	warn = level > M.WARN and silent or _G.print
	error = level > M.ERROR and silent or _G.print
	fatal = level > M.FATAL and silent or _G.print
end

function M.create(tag)
	tag = tag or ""

	local instance = {}

	function instance.debug(...) debug("DEBUG", tag, ...) end
	function instance.info(...) info("INFO", tag, ...) end
	function instance.warn(...) warn("WARN", tag, ...) end
	function instance.error(...) error("ERROR", tag, ...) end
	function instance.fatal(...) fatal("FATAL", tag, ...) end
	function instance.d(...) debug("DEBUG", tag, ...) end
	function instance.i(...) info("INFO", tag, ...) end
	function instance.w(...) warn("WARN", tag, ...) end
	function instance.e(...) error("ERROR", tag, ...) end
	function instance.f(...) fatal("FATAL", tag, ...) end

	return instance
end



return M
