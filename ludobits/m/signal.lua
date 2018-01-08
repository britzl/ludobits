--- Module to create a signal system where named signals can be created, listened
-- to and triggered
-- @usage

-- -- example_module.lua
-- local signal = require "ludobits.m.signal"
--
-- local M = {}
--
-- M.LOGIN_SUCCESS_SIGNAL = signal.create("login_success")
-- M.LOGOUT_SIGNAL = signal.create("logout")
--
-- function M.login()
--		.. perform async login and then
--		M.LOGIN_SUCCESS_SIGNAL.trigger({ user = "Foobar" })
-- end
--
-- function M.logout()
--		M.LOGOUT_SIGNAL.trigger()
-- end
--
-- return M
--
--
-- -- some.script
-- local example_module = require "example_module"
--
-- function init(self)
--		example_module.LOGIN_SUCCESS_SIGNAL.add(function(message)
--			print("login success", message.user)
--		end)
--		example_module.LOGOUT_SIGNAL.add()
-- end
--
-- function on_message(self, message_id, message, sender)
--		if message_id == hash(example_module.LOGOUT_SIGNAL.id) then
--			print("User logged out")
--		end
--	end


local M = {}


--- Create a signal
-- @param signal_id The unique id of the signal
-- @return The created signal
function M.create(signal_id)
	assert(signal_id, "You must provide a signal_id")
	local signal = {
		id = signal_id
	}

	local listeners = {}

	--- Add a listener to the signal
	-- @param cb Function callback or message url (defaults to current url)
	function signal.add(cb)
		cb = cb or msg.url()
		if type(cb) == "function" then
			listeners[cb] = { fn = cb }
		else
			local key = hash_to_hex(cb.socket or hash("")) .. hash_to_hex(cb.path or hash("")) .. hash_to_hex(cb.fragment or hash(""))
			listeners[key] = { fn = function(message) msg.post(cb, signal_id, message) end }
		end
	end

	--- Remove a listener from the signal
	-- @param cb Function callback or message url (defaults to current url)
	function signal.remove(cb)
		cb = cb or msg.url()
		if type(cb) == "function" then
			listeners[cb] = nil
		else
			local key = hash_to_hex(cb.socket or hash("")) .. hash_to_hex(cb.path or hash("")) .. hash_to_hex(cb.fragment or hash(""))
			listeners[key] = nil
		end
	end

	--- Trigger the signal
	-- @param message Message to pass to listeners
	function signal.trigger(message)
		assert(message, "You must provide a message")
		for k,v in pairs(listeners) do
			v.fn(message or {})
		end
	end

	return signal
end

return M
