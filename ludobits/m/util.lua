--- Utility functions

local M = {}

--- Suffle a Lua table
-- @param t The table to shuffle
function M.shuffle(t)
	local size = #t
	for i = size, 1, -1 do
		local rand = math.random(size)
		t[i], t[rand] = t[rand], t[i]
	end
	return t
end

--- Pick a random value from a list
-- @param list
-- @return value A random value
-- @return index Index of the value
function M.random(list)
	local i = math.random(1, #list)
	return list[i], i
end

--- Clamp a value to within a specific range
-- @param value The value to clamp
-- @param min Minimum value
-- @param max Maximum value
-- @return The value clamped to between min and max
function M.clamp(value, min, max)
	if value > max then return max end
	if value < min then return min end
	return value
end

-- http://www.rorydriscoll.com/2016/03/07/frame-rate-independent-damping-using-lerp/
-- return vmath.lerp(1 - math.pow(t, dt), v1, v2)
-- https://www.gamasutra.com/blogs/ScottLembcke/20180404/316046/Improved_Lerp_Smoothing.php
local UPDATE_FREQUENCY = tonumber(sys.get_config("display.update_frequency")) or 60
function M.lerp(t, dt, v1, v2)
	local rate = UPDATE_FREQUENCY * math.log10(1 - t)
	return vmath.lerp(1 - math.pow(10, rate * dt), v1, v2)
end

return M
