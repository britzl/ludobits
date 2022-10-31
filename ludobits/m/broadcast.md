# Broadcast
Module to simplify sending of a message to multiple receivers

## Usage

Register a listener:

```lua
-- receiver_a.script
local broadcast = require "ludobits.m.broadcast"

function init(self)
	-- listen to the "foo" message
	broadcast.register("foo")
end

function final(self)
	broadcast.unregister("foo")
end

function on_message(self, message_id, message, sender)
	if message_id == hash("foo") then
		-- handle message "foo"
		pprint(message)
	end
end
```

Broadcast a "foo" message:

```lua
-- broadcaster.script
local broadcast = require "ludobits.m.broadcast"

function update(self, dt)
	if some_condition then
		-- broadcast a "foo" message to anyone listening
		broadcast.send("foo", { something = 123 })
	end
end
```
