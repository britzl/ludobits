local M = {}

local instances = {}

local MSG_RESUME = hash("FLOW_RESUME")

local READY = "READY"
local RUNNING = "RUNNING"
local RESUMING = "RESUMING"
local WAITING = "WAITING"

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

function M.start(fn)
	assert(fn, "You must provide a function")
	return create_or_get(coroutine.create(fn))
end

function M.stop(instance)
	assert(instance, "You must provide a flow instance")
	instances[instance.co] = nil
end


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

function M.until_true(fn)
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	instance.condition = fn
	return coroutine.yield()
end

function M.until_any_message()
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	instance.on_message = function(message_id, message, sender)
		instance.result = { message_id = message_id, message = message }
		instance.on_message = nil
		instance.state = READY
	end
	return coroutine.yield()
end

function M.until_message(...)
	local message_ids_to_wait_for = { ... }
	local instance = create_or_get(coroutine.running())
	instance.state = WAITING
	instance.on_message = function(message_id, message, sender)
		for _, message_id_to_wait_for in pairs(message_ids_to_wait_for) do
			if message_id == message_id_to_wait_for then
				instance.result = { message_id = message_id, message = message }
				instance.on_message = nil
				instance.state = READY
				break
			end
		end
	end
	return coroutine.yield()
end

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
				coroutine.resume(co, result)
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