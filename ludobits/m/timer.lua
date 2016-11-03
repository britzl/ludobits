--- Simple timer module to delay a function call or
-- repeatedly call a function
--
-- @usage
-- function init(self)
-- 	self.t1 = timer.once(3, function()
-- 		print("t1 has fired")
-- 	end)
-- 	self.t2 = timer.every(1, function()
-- 		print("t2 has fired")
-- 	end)
-- 	self.t3 = timer(5, function()
-- 		print("t3 has fired")
-- 	end)
-- end
-- 
-- function update(self, dt)
-- 	self.t1.update(dt)
-- 	self.t2.update(dt)
-- 	self.t3.update(dt)
-- end

local M = {}


--- Create a timer that will call a function after a certain time
-- has elapsed.
-- @param seconds The number of seconds before the callback should be invoked
-- @param callback The function to invoke when the time has elapsed
-- @return The timer instance
function M.once(seconds, callback)
	assert(seconds and type(seconds) == "number" and seconds >= 0, "You must provide a positive number")
	assert(callback, "You must provide a callback")
	
	local timer = {
		seconds = seconds,
	}
	
	function timer.update(dt)
		assert(dt and type(dt) == "number", "You must provide a dt")
		if timer.seconds <= 0 then
			return
		end
		timer.seconds = timer.seconds - dt
		if timer.seconds <= 0 then
			callback(timer)
		end
	end
	
	function timer.reset()
		timer.seconds = seconds
	end
	
	return timer
end

--- Create a timer that will call a function with a regular interval
-- @param seconds The number of seconds between callbacks
-- @param callback The function to invoke
-- @return The timer instance
function M.every(seconds, callback)
	local timer = M.once(seconds, function(timer)
		callback(timer)
		timer.seconds = seconds
	end)
	return timer
end


return setmetatable(M, {
	__call = function(self, ...)
		return M.once(...)
	end
})