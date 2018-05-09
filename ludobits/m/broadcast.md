# Broadcast
Module to simplify sending of a message to multiple receivers

## Usage

	-- script_a.script
	local broadcast = require "ludobits.m.broadcast"

	function init(self)
		-- this script should react to "foo" and "bar" messages
		broadcast.register("foo")
		broadcast.register("bar", function(message, sender)
			-- handle message
		end)
	end

	function final(self)
		broadcast.unregister("foo")
		broadcast.unregister("bar")
	end

	function on_message(self, message_id, message, sender)
		if broadcast.on_message(message_id, message, sender) then
			-- message was handled
			return
		end
		if message_id == hash("foo") then
			-- handle message "foo"
		end
	end


	-- script_b.script
	local broadcast = require "ludobits.m.broadcast"

	function update(self, dt)
		if some condition then
			-- broadcast a "foo" message to anyone listening
			broadcast.send("foo")
		end
	end
