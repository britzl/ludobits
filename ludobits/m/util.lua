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

return M
