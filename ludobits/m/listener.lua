--- Listener implementation where listeners are added as urls and notified
-- via msg.post()
-- @usage
--
--	-- a.script
--	local listener = require "ludobits.m.listener"
--	
--	local l = listener.create()
--	l.add(msg.url("#myscript"))
--	l.trigger(hash("mymessage"), { foo = "bar" })
--
--
--	-- myscript.script
--	function on_message(self, mesage_id, message, sender)
--		if message_id == hash("mymessage") then
--			-- handle message from listener
--		end
--	end
--


local M = {}

--- Create a listener instance
-- @return Listener
function M.create()
	local listeners = {}
	
	local instance = {}
	
	
	function instance.add(url)
		listeners[url or msg.url()] = true
	end

	function instance.remove(url)
		listeners[url or msg.url()] = nil
	end
	
	function instance.trigger(message_id, message)
		assert(message_id, "You must provide a message_id")
		for url,_ in pairs(listeners) do
			msg.post(url, message_id, message or {})
		end
	end
	
	return instance
end


return M