--- Module to simplify loading/unloading of collections

local M = {}

local PROXY_LOADED = hash("proxy_loaded")
local PROXY_UNLOADED = hash("proxy_unloaded")

local on_loaded_callbacks = {}
local on_unloaded_callbacks = {}

local function ensure_hash(url)
	return type(url) == "string" and hash(url) or url
end

--- Load a collection and invoke a callback when loaded
-- @param collection_url
-- @param on_loaded The function to call when the collection has loaded
function M.load(collection_url, on_loaded)
	assert(collection_url, "You must provide a collection url to load")
	on_loaded_callbacks[tostring(collection_url)] = on_loaded
	msg.post(collection_url, "load")
end

--- Unload a collection
-- @param collection_url
function M.unload(collection_url)
	assert(collection_url, "You must provide a collection url to unload")
	msg.post(collection_url, "unload")
end

--- Forward any calls to on_message from scripts using this module
function M.on_message(message_id, message, sender)
	if message_id == PROXY_LOADED then
		msg.post(sender, "enable")
		local sender_string = tostring(sender)
		if on_loaded_callbacks[sender_string] then
			on_loaded_callbacks[sender_string]()
			on_loaded_callbacks[sender_string] = nil
		end
	end
end

return M