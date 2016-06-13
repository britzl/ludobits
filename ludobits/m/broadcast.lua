--- Module to simplify sending a message to multiple receivers

local M = {}

local receivers = {}

local function ensure_hash(string_or_hash)
	return type(string_or_hash) == "string" and hash(string_or_hash) or string_or_hash
end

--- Send a message to all registered receivers
-- @param message_id
-- @param message
function M.send(message_id, message)
	assert(message_id)
	local key = hash_to_hex(ensure_hash(message_id))
	if receivers[key] then
		message = message or {}
		for _,receiver_url in pairs(receivers[key]) do
			msg.post(receiver_url, message_id, message)
		end
	end
end

--- Register the current script as a receiver for a specific message
-- @param message_id
function M.register(message_id)
	assert(message_id)
	local key = hash_to_hex(ensure_hash(message_id))
	receivers[key] = receivers[key] or {}
	table.insert(receivers[key], msg.url())
end

--- Unregister the current script from receiving a previously registered message
-- @param message_id
function M.unregister(message_id)
	assert(message_id)
	local key = hash_to_hex(ensure_hash(message_id))
	if not receivers[key] then
		return
	end
	local my_url = msg.url()
	for i,receiver_url in pairs(receivers[key]) do
		if receiver_url == my_url then
			table.remove(receivers[key], i)
			return
		end
	end
end


return M