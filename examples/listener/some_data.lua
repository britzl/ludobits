local listener = require "ludobits.m.listener"

local M = {}

M.FOO = hash("foo")
M.BAR = hash("bar")

M.listeners = listener.create()

function M.trigger_foo()
	print("trigger_foo()")
	M.listeners.trigger(M.FOO, { text = "foo" })
end

function M.trigger_bar()
	print("trigger_bar()")
	M.listeners.trigger(M.BAR, { text = "bar" })
end

return M