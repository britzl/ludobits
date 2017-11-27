--- Module to simplify the use of several of the engine listeners.
-- The module allows the user to define multiple listeners for the iac, iap,
-- push and window listeners.
--
-- @usage
-- local app = require "ludobits.app"
--
-- local function iac_listener1(self, playload type)
-- 	print("This function will receive callbacks")
-- end
--
-- local function iac_listener2(self, playload type)
-- 	print("And this function too")
-- end
--
-- app.iac.add_listener(iac_listener1)
-- app.iac.add_listener(iac_listener2)


local M = {}

local function create_listener()
	local instance = {}

	local listeners = {}

	function instance.add(fn)
		listeners[fn] = true
	end

	function instance.remove(fn)
		listeners[fn] = nil
	end

	function instance.trigger(...)
		for fn,_ in pairs(listeners) do
			pcall(fn, ...)
		end
	end

	return instance
end




--- Wrapper for iac.set_listener
M.iac = {}

local iac_listener = create_listener()

function M.iac.add_listener(fn)
	if not iac then return end
	iac_listener.add(fn)
	iac.set_listener(iac_listener.trigger)
end

function M.iac.remove_listener(fn)
	iac_listener.remove(fn)
end

--- Wrapper for iap.set_listener
M.iap = {}

local iap_listener = create_listener()

function M.iap.add_listener(fn)
	if not iap then return end
	iap_listener.add(fn)
	iap.set_listener(iap_listener.trigger)
end

function M.iap.remove_listener(fn)
	iap_listener.remove(fn)
end


--- Wrapper for window.set_listener
M.window = {}

local window_listener = create_listener()

function M.window.add_listener(fn)
	if not window then return end
	window_listener.add(fn)
	window.set_listener(window_listener.trigger)
end

function M.window.remove_listener(fn)
	window_listener.remove(fn)
end

--- Wrapper for push.set_listener
M.push = {}

local push_listener = create_listener()

function M.push.add_listener(fn)
	if not push then return end
	push_listener.add(fn)
	push.set_listener(push_listener.trigger)
end

function M.push.remove_listener(fn)
	push_listener.remove(fn)
end



return M
