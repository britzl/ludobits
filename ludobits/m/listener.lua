--- Refer to listener.md for documentation

local M = {}

local function ensure_hash(s)
	return (type(s) == "string") and hash(s) or s
end

local function trigger_url(url, message_id, message)
	msg.post(url, message_id, message)
end

local function trigger_function(fn, message_id, message)
	fn(message_id, message)
end

--- Create a listener instance
-- @return Listener
function M.create()
	local any_listeners_url = {}
	local listeners = {}

	local instance = {}

	--- Add a function or url to invoke when the listener is triggered
	-- @param url_or_fn_to_add URL or function to call. Can be nil in which case the current URL is used.
	-- @param message_id Optional message id to filter on
	function instance.add(url_or_fn_to_add, message_id)
		url_or_fn_to_add = url_or_fn_to_add or msg.url()
		message_id = message_id and ensure_hash(message_id) or nil
		listeners[url_or_fn_to_add] = listeners[url_or_fn_to_add] or {}

		instance.remove(url_or_fn_to_add, message_id)
		table.insert(listeners[url_or_fn_to_add], {
			message_id = message_id,
			trigger = type(url_or_fn_to_add) == "userdata" and trigger_url or trigger_function
		})
	end

	--- Remove a previously added callback function or url
	-- @param url_or_fn_to_remove
	-- @param message_id Optional message_id to limit removal to
	function instance.remove(url_or_fn_to_remove, message_id)
		url_or_fn_to_remove = url_or_fn_to_remove or msg.url()
		message_id = message_id and ensure_hash(message_id) or nil

		local is_url = type(url_or_fn_to_remove) == "userdata"

		for url_fn,url_fn_listeners in pairs(listeners) do
			-- make sure to only check against urls if we are removing a url and vice versa
			if (is_url and type(url_fn) == "userdata") or (not is_url and type(url_fn) ~= "userdata") then
				for k,data in pairs(url_fn_listeners) do
					if is_url then
						if url_fn.socket == url_or_fn_to_remove.socket
						and url_fn.path == url_or_fn_to_remove.path
						and url_fn.fragment == url_or_fn_to_remove.fragment
						and (not message_id or message_id == data.message_id) then
							url_fn_listeners[k] = nil
						end
					else
						if url_fn == url_or_fn_to_remove and (not message_id or message_id == data.message_id) then
							url_fn_listeners[k] = nil
						end
					end
				end
			end
		end
	end

	--- Trigger this listener
	-- @param message_id Id of message to trigger
	-- @param message The message itself (can be nil)
	function instance.trigger(message_id, message)
		assert(message_id, "You must provide a message_id")
		assert(not message or type(message) == "table", "You must either provide no message or a message of type 'table'")
		message_id = ensure_hash(message_id)
		for url_fn,url_fn_listeners in pairs(listeners) do
			for _,listener in pairs(url_fn_listeners) do
				if not listener.message_id or listener.message_id == message_id then
					listener.trigger(url_fn, message_id, message or {})
				end
			end
		end
	end

	return instance
end


return M
