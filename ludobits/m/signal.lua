local M = {}


--- Create a signal
-- @param signal_id The unique id of the signal
-- @return The created signal
function M.create(signal_id)
	assert(signal_id, "You must provide a signal_id")
	signal_id = type(signal_id) == "string" and hash(signal_id) or signal_id
	local signal = {
		id = signal_id,
	}

	local listeners = {}

	--- Add a listener to the signal
	-- @param cb Function callback or message url (defaults to current url)
	function signal.add(cb)
		cb = cb or msg.url()
		if type(cb) == "function" then
			listeners[cb] = { fn = cb }
		else
			local key = hash_to_hex(cb.socket or hash("")) .. hash_to_hex(cb.path or hash("")) .. hash_to_hex(cb.fragment or hash(""))
			listeners[key] = {
				fn = function(message)
					if not message then
						msg.post(cb, signal_id)
					else
						if type(message) ~= "table" then
							message = { message = message }
						end
						msg.post(cb, signal_id, message)
					end
				end
			}
		end
	end

	--- Remove a listener from the signal
	-- @param cb Function callback or message url (defaults to current url)
	function signal.remove(cb)
		cb = cb or msg.url()
		if type(cb) == "function" then
			listeners[cb] = nil
		else
			local key = hash_to_hex(cb.socket or hash("")) .. hash_to_hex(cb.path or hash("")) .. hash_to_hex(cb.fragment or hash(""))
			listeners[key] = nil
		end
	end

	--- Trigger the signal
	-- @param message Optional message to pass to listeners
	function signal.trigger(message)
		for _,v in pairs(listeners) do
			v.fn(message)
		end
	end

	return signal
end

return M
