--- Listener implementation where listeners are added as either urls or functions
-- and notified when any or specific messages are received
--
-- @usage
--
--	-- a.script
--	local listener = require "ludobits.m.listener"
--	
--	local l = listener.create()
--
--	l.add(msg.url("#myscript"))
--	l.add(function(message_id, message)
--		-- handle message
--	end)
--	l.add({
--		[hash("mymessage")] = function(message_id, message)
--			-- handle "mymessage"
--		end,
--		[hash("foobar")] = msg.url("#myscript"),
--	})
--
--	l.trigger(hash("mymessage"), { text = "lorem ipsum" })
--	l.trigger(hash("foobar"), { foo = "bar" })
--
--
--	-- myscript.script
--	function on_message(self, mesage_id, message, sender)
--		if message_id == hash("mymessage") then
--			-- handle "mymessage"
--		elseif message_id == hahs("foobar") then
--			-- handle "foobar"
--		end
--	end
--


local M = {}

local function ensure_hash(s)
	return (type(s) == "string") and hash(s) or s
end

local function trigger_url(url, message_id, message)
	msg.post(url, message_id, message)
end

local function trigger_function(fn, message_id, message)
	fn(message_id, message)
end

--- Create a listener instance
-- @return Listener
function M.create()
	local any_listeners_url = {}
	local listeners = {}
	
	local instance = {}
	
	--- Add a function or url to invoke when the listener is triggered
	-- @param url_fn_table This can be one of three things:
	--	1. Function
	--	2. URL
	--  3. Table with mapping between specific message ids and functions or urls
	function instance.add(url_fn_table)
		if not url_fn_table then
			listeners[msg.url()] = {
				trigger = trigger_url
			}
		else
			if type(url_fn_table) == "table" then
				for message_id, url_fn in pairs(url_fn_table) do
					listeners[url_fn] = {
						message_id = ensure_hash(message_id),
						trigger = type(url_fn) == "function" and trigger_function or trigger_url
					}
				end
			else
				listeners[url_fn_table] = {
					trigger = type(url_fn_table) == "function" and trigger_function or trigger_url
				}
			end
		end
	end

	--- Remove a previously added callback function or url
	-- @param url_fn
	function instance.remove(url_fn)
		listeners[url_fn or msg.url()] = nil
	end
	
	--- Trigger this listener
	-- @param message_id Id of message to trigger
	-- @param message The message itself (can be nil)
	function instance.trigger(message_id, message)
		assert(message_id, "You must provide a message_id")
		message_id = ensure_hash(message_id)
		message = message or {}
		for url_fn,listener in pairs(listeners) do
			if not listener.message_id or listener.message_id == message_id then
				listener.trigger(url_fn, message_id, message)
			end
		end
	end
	
	return instance
end


return M