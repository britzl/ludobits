--- Module to simplify loading/unloading of collections
-- @usage
--
-- local collection = require "ludobits.m.collection"
--
-- function on_input(self, action_id, action)
--		collection.load("#proxy", function()
--			print("Collection loaded")
--		end)
--	end
--
-- function on_message(self, message_id, message, sender)
--		collection.on_message(message_id, message, sender)
-- end
--

local M = {}

local PROXY_LOADED = hash("proxy_loaded")
local PROXY_UNLOADED = hash("proxy_unloaded")

local on_loaded_callbacks = {}
local on_unloaded_callbacks = {}

local function url_to_key(url)
	local ok, url = pcall(msg.url, url)
	if not url then
		return nil
	end
	return url.socket .. hash_to_hex(url.path or hash("")) .. (hash_to_hex(url.fragment or hash("")))
end

local function ensure_url(url)
	return type(url) == "string" and msg.url(url) or url
end

--- Load a collection and invoke a callback when loaded
-- @param collection_url
-- @param on_loaded The function to call when the collection has loaded
function M.load(collection_url, on_loaded)
	assert(collection_url, "You must provide a collection url to load")
	local key = url_to_key(collection_url)
	if on_loaded_callbacks[key] then
		print("Already loading", collection_url)
		return
	end

	on_loaded_callbacks[key] = on_loaded or true
	msg.post(collection_url, "load")
end

--- Unload a collection
-- @param collection_url
-- @param on_unloaded The function to call when the collection has unloaded
function M.unload(collection_url, on_unloaded)
	assert(collection_url, "You must provide a collection url to unload")
	local key = url_to_key(collection_url)
	if on_unloaded_callbacks[key] then
		print("Already unloading", collection_url)
		return
	end

	on_unloaded_callbacks[key] = on_unloaded or true
	msg.post(collection_url, "unload")
end

--- Forward any calls to on_message from scripts using this module
function M.on_message(message_id, message, sender)
	if message_id == PROXY_LOADED then
		msg.post(sender, "enable")

		local key = url_to_key(sender)
		if on_loaded_callbacks[key] then
			if type(on_loaded_callbacks[key]) == "function" then
				on_loaded_callbacks[key]()
			end
			on_loaded_callbacks[key] = nil
		end
	elseif message_id == PROXY_UNLOADED then
		local key = url_to_key(sender)
		if on_unloaded_callbacks[key] then
			if type(on_unloaded_callbacks[key]) == "function" then
				on_unloaded_callbacks[key]()
			end
			on_unloaded_callbacks[key] = nil
		end
	end
end

return M