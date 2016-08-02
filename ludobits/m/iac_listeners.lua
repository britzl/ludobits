--- Module to allow multiple IAC listeners set at the same time.
-- This module will set itself as the IAC listener and when an IAC
-- callback happens it will forward the IAC payload and type to all
-- registered listeners 

local M = {}

local listeners = {}

function M.add(fn)
	iac.set_listener(function(self, payload, type)
		for fn,_ in pairs(listeners) do
			fn(self, payload, type)
		end
	end)

	listeners[fn] = true
end

function M.remove(fn)
	listeners[fn] = nil
end


return M