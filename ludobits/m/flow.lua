local M = {}

local instances = {}

local MSG_RESUME = hash("FLOW_RESUME")

local READY = "READY"
local RUNNING = "RUNNING"
local RESUMING = "RESUMING"
local WAITING = "WAITING"


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


local function create_or_get(co)
	assert(co, "You must provide a coroutine")
	if not instances[co] then
		instances[co] = {
			id = socket.gettime(),
			url = msg.url(),
			state = READY,
			co = co,
		}
	end
	return instances[co]
end 


--- Start a new flow. This will either create a new
-- coroutine or create one if this function isn't called
-- from witin a coroutine
-- @param fn The function to run within the flow
-- @return The created flow instance
function M.start(fn)
	assert(fn, "You must provide a function")
	return create_or_get(coroutine.create(fn))
end


--- Stop a created flow before it has completed
-- @param instance This can be either the returned value from
-- a call to @{start}, a coroutine or URL
function M.stop(instance)
	assert(instance, "You must provide a flow instance")
	if type(instance) == "table" then
		assert(instance.co, "The provided instance doesn't contain a coroutine")
		instances[instance.co] = nil
	elseif type(instance) == "thread" then
		instances[instance] = nil
	else
		for k,v in pairs(instances) do
			if v.url == instance then
				instances[k] = nil
				return
			end
			print("Warning: Unable to find a flow instance to remove for", instance)
		end
	end
end


--- Wait until a certain time has elapsed
-- @param seconds
function M.delay(seconds)
	assert(seconds, "You must provide a delay")
	local instance = create_or_get(coroutine.running())
	local now = socket.gettime()
	instance.state = WAITING
	instance.condition = function()
		return socket.gettime() > (now + seconds) 
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


--- Wait until a function returns true
-- @param fn
function M.until_true(fn)
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


--- Wait until a callback function is invoked
-- @param fn The function to call. The function must take a callback function as its first argument
-- @param arg1 Additional argument to pass to fn
-- @param arg2 Additional argument to pass to fn
-- @param argn Additional argument to pass to fn
-- @return Any values passed to the callback function
function M.until_callback(fn, ...)
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	fn(function(...)
		instance.state = READY
		instance.result = table_pack(...)
	end)
	return coroutine.yield()
end


--- Load a collection and wait until it is loaded and enabled
-- @param collection_url
function M.load(collection_url)
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	instance.on_message = function(message_id, message, sender)
		if message_id == hash("proxy_loaded") and sender == collection_url then
			msg.post(sender, "enable")
			instance.state = READY
		end
	end
	msg.post(collection_url, "load")
	return coroutine.yield()
end


--- Unload a collection and wait until it is unloaded
-- @param collection_url The collection to unload
function M.unload(collection_url)
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	instance.on_message = function(message_id, message, sender)
		if message_id == hash("proxy_unloaded") and sender == collection_url then
			instance.state = READY
		end
	end
	msg.post(collection_url, "unload")
	return coroutine.yield()
end


function M.update()
	for co,instance in pairs(instances) do
		local status = coroutine.status(co)
		if status == "dead" then
			instances[co] = nil
		else
			if instance.state == WAITING and instance.condition then
				if instance.condition() then
					instance.condition = nil
					instance.on_message = nil
					instance.state = READY
				end
			end
			
			if instance.state == READY then
				instance.state = RESUMING
				msg.post(instance.url, MSG_RESUME, { url = instance.url, id = instance.id })
			end
		end
	end
end


function M.on_message(message_id, message, sender)
	if message_id == MSG_RESUME then
		for co,instance in pairs(instances) do
			if instance.id == message.id then
				instance.state = RUNNING
				local result = instance.result or {}
				instance.result = nil
				coroutine.resume(co, table_unpack(result))
				return
			end
		end
	else
		for _,instance in pairs(instances) do
			if instance.on_message then
				instance.on_message(message_id, message, sender)
			end
		end
	end
end

return M