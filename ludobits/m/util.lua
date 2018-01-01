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


return M
