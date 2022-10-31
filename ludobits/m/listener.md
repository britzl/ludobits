# Listener
Listener implementation where listeners are added as either urls or functions and notified when any or specific messages are received

# Usage

```lua
	-- a.script
	local listener = require "ludobits.m.listener"

	local l = listener.create()

	local function handler1(message_id, message)
		print(message_id)
	end

	local function handler2(message_id, message)
		print(message_id)
	end

	-- add listener function handler1 and listen to all messages

	l.add(handler1)

	-- add listener function handler2 and only listen to "mymessage1" and "mymessage2"
	l.add(handler2, "mymessage1")
	l.add(handler2, "mymessage2")

	-- add listener url "#myscript1" and listen to all messages
	l.add(msg.url("#myscript1"))

	-- add listener url "#myscript2" and only listen to "mymessage1" and "mymessage2"
	l.add(msg.url("#myscript2"), "mymessage1")
	l.add(msg.url("#myscript2"), "mymessage2")


	-- trigger some messages
	l.trigger(hash("mymessage1"), { text = "lorem ipsum" })
	l.trigger(hash("mymessage2"), { text = "lorem ipsum" })
	l.trigger(hash("mymessage3"), { text = "lorem ipsum" })
	l.trigger(hash("foobar"), { foo = "bar" })
```

```lua
	--myscript1.script
	function on_message(self, mesage_id, message, sender)
		print(message_id)
	end
```

```lua
	-- myscript2.script
	function on_message(self, mesage_id, message, sender)
		print(message_id)
	end
```