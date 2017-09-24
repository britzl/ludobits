local M = {}

function M.create(signal_id)
	assert(signal_id, "You must provide a signal_id")
	local signal = {
		id = signal_id
	}

	local listeners = {}

	function signal.add(cb)
		cb = cb or msg.url()
		if type(cb) == "function" then
			listeners[cb] = { fn = cb }
		else
			local key = hash_to_hex(cb.socket or hash("")) .. hash_to_hex(cb.path or hash("")) .. hash_to_hex(cb.fragment or hash(""))
			listeners[key] = { fn = function(message) msg.post(cb, signal_id, message) end }
		end
	end

	function signal.remove(cb)
		cb = cb or msg.url()
		if type(cb) == "function" then
			listeners[cb] = nil
		else
			local key = hash_to_hex(cb.socket or hash("")) .. hash_to_hex(cb.path or hash("")) .. hash_to_hex(cb.fragment or hash(""))
			listeners[key] = nil
		end
	end

	function signal.trigger(message)
		assert(message, "You must provide a message")
		for k,v in pairs(listeners) do
			v.fn(message)
		end
	end

	return signal
end

return M