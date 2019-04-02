# Broadcast
Module to simplify sending of a message to multiple receivers

## Usage

	-- receiver_a.script
	local broadcast = require "ludobits.m.broadcast"

	function init(self)
		broadcast.register("foo")
	end

	function final(self)
		broadcast.unregister("foo")
	end

	function on_message(self, message_id, message, sender)
		if message_id == hash("foo") then
			-- handle message "foo"
		end
	end

	-- receiver_b.script
	local broadcast = require "ludobits.m.broadcast"

	function init(self)
		broadcast.register("bar", function(message, sender)
			-- handle message
		end)
	end

	function final(self)
		broadcast.unregister("bar")
	end

	function on_message(self, message_id, message, sender)
		if broadcast.on_message(message_id, message, sender) then
			-- message was handled
			return
		end
	end


	-- broadcaster.script
	local broadcast = require "ludobits.m.broadcast"

	function update(self, dt)
		if some condition then
			-- broadcast a "foo" message to anyone listening
			broadcast.send("foo")
		end
	end
