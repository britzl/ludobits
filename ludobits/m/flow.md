The flow module simplifies asynchronous flows of execution where your code needs to wait for one asynchronous operation to finish before starting with the next one.

Example:

```lua
local flow = require "ludobits.m.flow"

function init(self)
	flow.start(function()
		-- animate a gameobject and wait for animation to complete
		flow.go_animate(".", "position.y", go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_INCUBIC, 2)
		-- wait for one and a half seconds
		flow.delay(1.5)
		-- wait until a function returns true
		flow.until_true(is_game_over)
		-- animate go again
		flow.go_animate(".", "position.y", go.PLAYBACK_ONCE_FORWARD, 400, go.EASING_INCUBIC, 2)
	end)
end

function final(self)
	flow.stop()
end

function on_message(self, message_id, message, sender)
	flow.on_message(message_id, message, sender)
end
```

Complete API below (also refer to the examples for usage):

```lua
-- Start a new flow
local instance = flow.start(fn, options, on_error)


-- Stop a created flow before it has completed
flow.stop(instance)


-- Wait until a certain time has elapsed
flow.delay(seconds)


-- Wait until a certain number of frames have elapsed
flow.frames(frames)


-- Yield execution for one frame
flow.yield()


-- Wait until a function returns true
flow.until_true(fn)


-- Wait until any message is received
-- NOTE: You need to call flow.on_message()
flow.until_any_message()


-- Wait until a specific message is received
-- NOTE: You need to call flow.on_message()
flow.until_message(...)


-- Waiting to receive all specific messages.
-- NOTE: You need to call flow.on_message()
flow.until_all_messages(...)


-- Wait until input action with pressed state
-- NOTE: You need to call flow.on_message()
flow.until_input_pressed(...)


-- Wait until input action with released state
-- NOTE: You need to call flow.on_input()
flow.until_input_released(...)


-- Wait until a callback function is invoked
flow.until_callback(fn, ...)


-- Load a collection and wait until it is loaded and enabled
-- NOTE: You need to call flow.on_message()
flow.load(collection_url)


-- Load a collection asynchronously and wait until it is loaded and enabled
-- NOTE: You need to call flow.on_message()
flow.load_async(collection_url)

-- Unload a collection and wait until it is unloaded
-- NOTE: You need to call flow.on_message()
flow.unload(collection_url)


-- Load the resources used by a factory
-- NOTE: You need to call flow.on_message()
flow.load_factory(factory_url)

-- Load the resources used by a collection factory
-- NOTE: You need to call flow.on_message()
flow.load_collection_factory(collectionfactory_url)


-- Call go.animate and wait until it has finished
flow.go_animate(url, property, playback, to, easing, duration, delay)


-- Call gui.animate and wait until it has finished
flow.gui_animate(node, property, playback, to, easing, duration, delay)


-- Play a sprite animation and wait until it has finished
flow.play_animation(sprite_url, id)


-- Wait until other flow coroutines were finished
flow.until_flows(flows)


-- Wait until other flow coroutines with a specific group_id were finished
flow.until_group(group_id)


-- Forward any received messages in your scripts to this function
flow.on_message(message_id, message, sender)


-- Forward any received input in your scripts to this function
flow.on_input(action_id, action)

```
