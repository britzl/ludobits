--- The flow module simplifies asynchronous flows of execution where your
-- code needs to wait for one asynchronous operation to finish before
-- starting with the next one.
--
-- @usage
--
-- 	local flow = require "ludobits.m.flow"
--
-- 	function init(self)
-- 		flow.start(function()
-- 			-- animate a gameobject and wait for animation to complete
-- 			flow.go_animate(".", "position.y", go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_INCUBIC, 2)
-- 			-- wait for one and a half seconds
-- 			flow.delay(1.5)
-- 			-- wait until a function returns true
-- 			flow.until_true(is_game_over)
-- 			-- animate go again
-- 			flow.go_animate(".", "position.y", go.PLAYBACK_ONCE_FORWARD, 400, go.EASING_INCUBIC, 2)
-- 		end)
-- 	end
--
-- 	function final(self)
-- 		flow.stop()
-- 	end
--
-- 	function update(self, dt)
-- 		flow.update()
-- 	end
--
-- 	function on_message(self, message_id, message, sender)
-- 		flow.on_message(message_id, message, sender)
-- 	end
--

local M = {}

local instances = {}

local MSG_RESUME = hash("FLOW_RESUME")

local READY = "READY"
local RUNNING = "RUNNING"
local RESUMING = "RESUMING"
local WAITING = "WAITING"


local RAY_CAST_RESPONSE = hash("ray_cast_response")
local PLAY_ANIMATION = hash("play_animation")
local PROXY_LOADED = hash("proxy_loaded")
local PROXY_UNLOADED = hash("proxy_unloaded")

local function ensure_url(url)
	return (type(url) == "string") and msg.url(url) or url
end

local function ensure_hash(s)
	return (type(s) == "string") and hash(s) or s
end

local function table_pack(...)
	return { n = select("#", ...), ... }
end

local function table_unpack(args)
	if args then
		return unpack(args, 1, args.n or #args)
	else
		return nil
	end
end

local id_counter = 0

local function create_or_get(co)
	assert(co, "You must provide a coroutine")
	if not instances[co] then
		id_counter = id_counter + 1
		instances[co] = {
			id = id_counter,
			url = msg.url(),
			state = READY,
			co = co,
			script_instance = _G.__dm_script_instance__,
		}
	end
	return instances[co]
end


--- Start a new flow. If this function is called from
-- within an existing flow the existing flow can either
-- wait for the new flow to finish or run in parallel
-- @param fn The function to run within the flow
-- @param options Key value pairs. Allowed keys:
--		parallel = true if running flow shouldn't wait for this flow
-- @param on_error Function to call if something goes wrong while
-- running the flow
-- @return The created flow instance
function M.start(fn, options, on_error)
	assert(fn, "You must provide a function")
	local co = coroutine.running()
	if not co or not instances[co] or (options and options.parallel) then
		local created_instance = create_or_get(coroutine.create(fn))
		created_instance.on_error = on_error
		return created_instance
	else
		local running_instance = instances[co]
		local created_instance = create_or_get(coroutine.create(fn))
		created_instance.on_error = on_error
		M.until_true(function()
			return instances[created_instance.co] == nil
		end)
		return created_instance
	end
end


function M.parallel(fn, on_error)
	return M.start(fn, { parallel = true }, on_error)
end


--- Stop a created flow before it has completed
-- @param instance This can be either the returned value from
-- a call to @{start}, a coroutine or URL. Defaults to the URL of the
-- running script
function M.stop(instance)
	instance = instance or msg.url()
	if type(instance) == "table" then
		assert(instance.co, "The provided instance doesn't contain a coroutine")
		instances[instance.co] = nil
	elseif type(instance) == "thread" then
		instances[instance] = nil
	else
		for k,v in pairs(instances) do
			if v.url == instance then
				instances[k] = nil
			end
		end
	end
end


--- Wait until a certain time has elapsed
-- @param seconds
function M.delay(seconds)
	assert(seconds, "You must provide a delay")
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	instance.condition = function(dt)
		seconds = seconds - dt
		return seconds <= 0
	end
	return coroutine.yield()
end


--- Wait until a certain number of frames have elapsed
-- @param frames
function M.frames(frames)
	assert(frames, "You must provide a number of frames to wait")
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	instance.condition = function()
		frames = frames - 1
		return frames == 0
	end
	return coroutine.yield()
end


function M.yield()
	return coroutine.yield()
end


--- Wait until a function returns true
-- @param fn
function M.until_true(fn)
	assert(fn, "You must provide a function")
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	instance.condition = fn
	return coroutine.yield()
end


--- Wait until any message is received
-- @return message_id
-- @return message
-- @return sender
function M.until_any_message()
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	instance.on_message = function(message_id, message, sender)
		instance.result = table_pack(message_id, message, sender)
		instance.on_message = nil
		instance.state = READY
	end
	return coroutine.yield()
end


--- Wait until a specific message is received
-- @param message_1 Message to wait for
-- @param message_2 Message to wait for
-- @param message_n Message to wait for
-- @return message_id
-- @return message
-- @return sender
function M.until_message(...)
	local message_ids_to_wait_for = { ... }
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	instance.on_message = function(message_id, message, sender)
		for _, message_id_to_wait_for in pairs(message_ids_to_wait_for) do
			if message_id == message_id_to_wait_for then
				instance.result = table_pack(message_id, message, sender)
				instance.on_message = nil
				instance.state = READY
				break
			end
		end
	end
	return coroutine.yield()
end


--- Wait until input action with pressed state
-- @param action_1 Action to wait for (nil for any action)
-- @param action_2 Action to wait for
-- @param action_n Action to wait for
-- @return action_id
-- @return action
function M.until_input_pressed(...)
	local action_ids_to_wait_for = { ... }
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	if #action_ids_to_wait_for == 0 then
		instance.on_input = function(action_id, action)
			if action_id and action.pressed then
				instance.result = table_pack(action_id, action)
				instance.on_input = nil
				instance.state = READY
			end
		end
	else
		instance.on_input = function(action_id, action)
			if action_id and action.pressed then
				for _, action_id_to_wait_for in pairs(action_ids_to_wait_for) do
					if action_id == action_id_to_wait_for then
						instance.result = table_pack(action_id, action)
						instance.on_input = nil
						instance.state = READY
						break
					end
				end
			end
		end
	end
	return coroutine.yield()
end


--- Wait until input action with released state
-- @param action_1 Action to wait for (nil for any action)
-- @param action_2 Action to wait for
-- @param action_n Action to wait for
-- @return action_id
-- @return action
function M.until_input_released(...)
	local action_ids_to_wait_for = { ... }
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	if #action_ids_to_wait_for == 0 then
		instance.on_input = function(action_id, action)
			if action_id and action.released then
				instance.result = table_pack(action_id, action)
				instance.on_input = nil
				instance.state = READY
			end
		end
	else
		instance.on_input = function(action_id, action)
			if action_id and action.released then
				for _, action_id_to_wait_for in pairs(action_ids_to_wait_for) do
					if action_id == action_id_to_wait_for then
						instance.result = table_pack(action_id, action)
						instance.on_input = nil
						instance.state = READY
						break
					end
				end
			end
		end
	end
	return coroutine.yield()
end

--- Wait until a callback function is invoked
-- @param fn The function to call. The function must take a callback function as its first argument
-- @param arg1 Additional argument to pass to fn
-- @param arg2 Additional argument to pass to fn
-- @param argn Additional argument to pass to fn
-- @return Any values passed to the callback function
function M.until_callback(fn, ...)
	assert(fn, "You must provide a function")
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	fn(function(...)
		instance.state = READY
		instance.result = table_pack(...)
	end, ...)
	return coroutine.yield()
end


--- Load a collection and wait until it is loaded and enabled
-- @param collection_url
function M.load(collection_url)
	assert(collection_url, "You must provide a URL to a collection proxy")
	collection_url = ensure_url(collection_url)
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	instance.on_message = function(message_id, message, sender)
		if message_id == PROXY_LOADED and sender == collection_url then
			msg.post(sender, "enable")
			instance.on_message = nil
			instance.state = READY
		end
	end
	msg.post(collection_url, "load")
	return coroutine.yield()
end


--- Unload a collection and wait until it is unloaded
-- @param collection_url The collection to unload
function M.unload(collection_url)
	assert(collection_url, "You must provide a URL to a collection proxy")
	collection_url = ensure_url(collection_url)
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	instance.on_message = function(message_id, message, sender)
		if message_id == PROXY_UNLOADED and sender == collection_url then
			instance.state = READY
		end
	end
	msg.post(collection_url, "unload")
	return coroutine.yield()
end


--- Call go.animate and wait until it has finished
-- @param url
-- @param property
-- @param playback
-- @param to
-- @param easing
-- @param duration
-- @param delay
function M.go_animate(url, property, playback, to, easing, duration, delay)
	assert(url, "You must provide a URL")
	assert(property, "You must provide a property to animate")
	assert(to, "You must provide a value to animate to")
	assert(easing, "You must provide an easing value")
	assert(duration, "You must provide a duration")
	M.until_callback(function(cb)
		go.cancel_animations(url, property)
		go.animate(url, property, playback, to, easing, duration, delay or 0, cb)
	end)
end


--- Call gui.animate and wait until it has finished
-- NOTE: The argument order differs from gui.animate() (playback is shifted
-- to the same position as for go.animate)
-- @param node
-- @param property
-- @param playback
-- @param to
-- @param easing
-- @param duration
-- @param delay
function M.gui_animate(node, property, playback, to, easing, duration, delay)
	assert(node, "You must provide a node")
	assert(property, "You must provide a property to animate")
	assert(to, "You must provide a value to animate to")
	assert(easing, "You must provide an easing value")
	assert(duration, "You must provide a duration")
	M.until_callback(function(cb)
		gui.cancel_animation(node, property)
		gui.animate(node, property, to, easing, duration, delay or 0, cb, playback)
	end)
end


--- Play a sprite animation and wait until it has finished
-- @param sprite_url
-- @param id
function M.play_animation(sprite_url, id)
	assert(sprite_url, "You must provide a sprite url")
	assert(id, "You must provide an animation id")
	sprite_url = ensure_url(sprite_url)
	id = ensure_hash(id)
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	instance.on_message = function(message_id, message, sender)
		if message_id == hash("animation_done") and sender == sprite_url then
			instance.state = READY
		end
	end
	msg.post(sprite_url, PLAY_ANIMATION, { id = id })
	return coroutine.yield()
end


local raycast_request_id_counter = 0


--- Cast a physics ray and wait for a response for a maximum of one frame
-- @param from
-- @param to
-- @param groups
-- @return The ray cast response or nil if no hit
function M.ray_cast(from, to, groups)
	assert(from, "You must provide a position to cast ray from")
	assert(to, "You must provide a position to cast ray to")
	assert(groups, "You must provide a list of groups")
	local request_id = raycast_request_id_counter
	raycast_request_id_counter = raycast_request_id_counter + 1
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	instance.on_message = function(message_id, message, sender)
		if message_id == RAY_CAST_RESPONSE and message.request_id == request_id then
			instance.result = table_pack(message)
			instance.condition = nil
			instance.state = READY
		end
	end
	local frames = 1
	instance.condition = function()
		frames = frames - 1
		return frames == 0
	end
	physics.ray_cast(from, to, groups, request_id)
	return coroutine.yield()
end


local function resume(instance)
	instance.state = RUNNING
	local result = instance.result or {}
	instance.result = nil
	local ok, error = coroutine.resume(instance.co, table_unpack(result))
	if not ok then
		if instance.on_error then
			instance.on_error(error)
		else
			print("Warning: Flow resulted in error", error)
		end
	end
end

--- Call this as often as needed (every frame)
function M.update(dt)
	if not dt then
		print("WARN: flow.update() now requires dt. Assuming 0.0167 for now.")
		dt = 0.0167
	end
	for co,instance in pairs(instances) do
		local status = coroutine.status(co)
		if status == "dead" then
			instances[co] = nil
		else
			local current_script_instance = _G.__dm_script_instance__
			_G.__dm_script_instance__ = instance.script_instance

			if instance.state == WAITING and instance.condition then
				if instance.condition(dt) then
					instance.condition = nil
					instance.on_message = nil
					instance.state = READY
				end
			end

			if instance.state == READY then
				resume(instance)
			end

			_G.__dm_script_instance__ = current_script_instance
		end
	end
end


--- Forward any received messages in your scripts to this function
function M.on_message(message_id, message, sender)
	local url = msg.url()
	for _,instance in pairs(instances) do
		if instance.on_message and instance.url == url then
			instance.on_message(message_id, message, sender)
		end
	end
end

function M.on_input(action_id, action)
	local url = msg.url()
	for _,instance in pairs(instances) do
		if instance.on_input and instance.url == url then
			instance.on_input(action_id, action)
		end
	end
end

return setmetatable(M, {
	__call = function(self, ...)
		return M.start(...)
	end
})
