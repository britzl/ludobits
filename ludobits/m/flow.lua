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

local function ensure_hashes(t)
	for k,v in pairs(t) do
		t[k] = ensure_hash(v)
	end
	return t
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


local function resume(instance)
	instance.state = RUNNING
	local result = instance.result or {}
	instance.result = nil
	local ok, error = coroutine.resume(instance.co, table_unpack(result))
	if not ok then
		if instance.on_error then
			instance.on_error(error)
		else
			pprint(debug.traceback(instance.co, error, 1))
		end
	end
end

local function update_flow(dt, co)
	local status = coroutine.status(co)
	if status == "dead" then
		instances[co] = nil
	else
		local instance = instances[co]
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
	end
end

local id_counter = 0

local function create_or_get(co, group_id)
	assert(co, "You must provide a coroutine")
	if not instances[co] then
		id_counter = id_counter + 1
		instances[co] = {
			id = id_counter,
			url = msg.url(),
			state = READY,
			co = co,
			group_id = group_id and ensure_hash(group_id),
			timer_id = timer.delay(0, true, function(self, handle, time_elapsed)
				if not instances[co] then
					timer.cancel(handle)
					return
				end
				update_flow(time_elapsed, co)
			end),
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
--		group_id = hash("group") if you want to use it in until_group() later
-- @param on_error Function to call if something goes wrong while
-- running the flow
-- @return The created flow instance
function M.start(fn, options, on_error)
	assert(fn, "You must provide a function")
	local group_id = options and ensure_hash(options.group_id)

	local created_instance = create_or_get(coroutine.create(fn), group_id)
	created_instance.on_error = on_error

	local parallel = options and options.parallel
	local co = coroutine.running()
	if co and instances[co] and not parallel then
		M.until_true(function()
			return instances[created_instance.co] == nil
		end)
	else
		update_flow(0, created_instance.co)
	end 
	return created_instance
end


function M.parallel(fn, on_error)
	return M.start(fn, { parallel = true }, on_error)
end

function M.parallel_group(group_id, fn, on_error)
	return M.start(fn, { parallel = true, group_id = group_id }, on_error)
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
		resume(instance)
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
	local message_ids_to_wait_for = ensure_hashes({ ... })
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	instance.on_message = function(message_id, message, sender)
		for _, message_id_to_wait_for in pairs(message_ids_to_wait_for) do
			if message_id == message_id_to_wait_for then
				instance.result = table_pack(message_id, message, sender)
				instance.on_message = nil
				instance.state = READY
				resume(instance)
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
	local action_ids_to_wait_for =  ensure_hashes({ ... })
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	if #action_ids_to_wait_for == 0 then
		instance.on_input = function(action_id, action)
			if action_id and action.pressed then
				instance.result = table_pack(action_id, action)
				instance.on_input = nil
				instance.state = READY
				resume(instance)
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
						resume(instance)
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
	local action_ids_to_wait_for = ensure_hashes({ ... })
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	if #action_ids_to_wait_for == 0 then
		instance.on_input = function(action_id, action)
			if action_id and action.released then
				instance.result = table_pack(action_id, action)
				instance.on_input = nil
				instance.state = READY
				resume(instance)
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
						resume(instance)
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


local function load_collection_proxy(collection_url, method)
	assert(collection_url, "You must provide a URL to a collection proxy")
	assert(method)
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
	msg.post(collection_url, method)
	return coroutine.yield()
end

--- Load a collection and wait until it is loaded and enabled
-- @param collection_url
function M.load(collection_url)
	return load_collection_proxy(collection_url, "load")
end


--- Load a collection asynchronously and wait until it is loaded and enabled
-- @param collection_url
function M.load_async(collection_url)
	return load_collection_proxy(collection_url, "async_load")
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

--- Load the resources used by a factory
-- @param factory_url The factory to load resources for
-- @return True if resources were loaded sucessfully
function M.load_factory(factory_url)
	assert(factory_url, "You must provide a URL to a factory")
	M.until_callback(function(cb)
		factory.load(factory_url, function(self, url, result)
			cb(result)
		end)
	end)
end

--- Load the resources used by a collection factory
-- @param factory_url The collection factory to load resources for
-- @return True if resources were loaded sucessfully
function M.load_collection_factory(collectionfactory_url)
	assert(collectionfactory_url, "You must provide a URL to a collection factory")
	M.until_callback(function(cb)
		collectionfactory.load(collectionfactory_url, function(self, url, result)
			cb(result)
		end)
	end)
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
	M.until_callback(function(cb)
		sprite.play_flipbook(sprite_url, id, cb)
	end)
end

--- Wait until other flow coroutines were finished
-- @param flows one coroutine or array of coroutines
function M.until_flows(flows)
	assert(flows)

	-- single coroutine
	if flows.co then
		M.until_true(function()
			return coroutine.status(flows.co) == "dead"
		end)
		return
	end

	-- several coroutines
	for _, instance in pairs(flows) do
		M.until_true(function()
			return coroutine.status(instance.co) == "dead"
		end)
	end
end

--- Wait until other flow coroutines with a specific group_id were finished
-- @param group_id identifier of the flows group
function M.until_group(group_id)
	assert(group_id)
	local group_id = ensure_hash(group_id)
	local group = {}

	for _, instance in pairs(instances) do
		if instance.group_id == group_id then
			table.insert(group, instance)
		end
	end

	if #group > 0 then
		M.until_flows(group)
	end
end

function M.ray_cast()
	print("flow.ray_cast() is deprecated. Use synchronous ray casts released in Defold 1.2.150 instead!")
end

function M.update()
	print("flow.update() is deprecated. You no longer need to call it!")
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
