--- Module to simplify sending a message to multiple receivers
local listener = require "ludobits.m.listener"

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
	local key = ensure_hash(message_id)
	if receivers[key] then
		message = message or {}
		receivers[key].trigger(message_id, message)
	end
end

--- Register the current script as a receiver for a specific message
-- @param message_id
-- @param url_or_fn Optional URL or function to register. Defaults to the
-- current script url
function M.register(message_id, url_or_fn)
	assert(message_id)
	url_or_fn = url_or_fn or msg.url()
	local key = ensure_hash(message_id)
	receivers[key] = receivers[key] or listener.create()
	receivers[key].add(url_or_fn)
end

--- Unregister the current script from receiving a previously registered message
-- @param message_id
-- @param url_or_fn Optional URL or function to unregister. Defaults to the current
-- script url
function M.unregister(message_id, url_or_fn)
	assert(message_id)
	url_or_fn = url_or_fn or msg.url()
	local key = ensure_hash(message_id)
	if receivers[key] then
		receivers[key].remove(url_or_fn)
	end
end


return M