--- Gesture detection module that can be used to detect gestures such as tap, double tap,
-- long press and swipe
-- @usage
--
--	local gesture = require "ludobits.m.gesture"
--	
--	function on_input(self, action_id, action)
--		local g = gesture.on_input(self, action_id, action)
--		if g.tap then
--			print("Single tap detected")
--		elseif g.double_tap then
--			print("Double tap detected")
--		elseif g.long_press then
--			print("Long-press detected")
--		elseif g.swipe_left then
--			print("Swipe left detected")
--		elseif g.swipe_right then
--			print("Swipe right detected")
--		elseif g.swipe_up then
--			print("Swipe up detected")
--		elseif g.swipe_down then
--			print("Swipe down detected")
--		end
--	end
--


local M = {}

M.HASH_TOUCH = hash("touch")

-- maximum distance between a pressed and release action to consider it a tap
M.TAP_THRESHOLD = 20

M.DOUBLE_TAP_INTERVAL = 0.5

-- minimum distance between a pressed and release action to consider it a swipe
M.SWIPE_THRESHOLD = 50

-- maximum time between a pressed and release action to consider it a swipe
M.SWIPE_TIME = 0.5

-- minimum time of a pressed/release sequence to consider it a long press
M.LONG_PRESS_TIME = 0.5

local contexts = {}

function M.on_input(self, action_id, action)
	if action_id ~= M.HASH_TOUCH then
		return
	end
	if not contexts[self] then
		contexts[self] = {
			gestures = {
				tap = false,
				double_tap = false,
				long_press = false,
				swipe_left = false,
				swipe_right = false,
				swipe_up = false,
				swipe_down = false,
				swipe = nil,
			}
		}
	end
	local c = contexts[self]
	c.gestures.tap = false
	c.gestures.double_tap = false
	c.gestures.long_press = false
	c.gestures.swipe_left = false
	c.gestures.swipe_right = false
	c.gestures.swipe_up = false
	c.gestures.swipe_down = false
	c.gestures.swipe = nil

	if action.pressed then
		c.pressed = true
		c.pressed_action = action
		c.pressed_time = socket.gettime()
	elseif action.released then
		local dx = c.pressed_action and (c.pressed_action.x - action.x) or 0
		local dy = c.pressed_action and (c.pressed_action.y - action.y) or 0
		local ax = math.abs(dx)
		local ay = math.abs(dy)
		local distance = math.max(ax, ay)
		local time = socket.gettime() - (c.pressed_time or 0)
		local tap = distance < M.TAP_THRESHOLD
		local swipe = distance >= M.SWIPE_THRESHOLD and time <= M.SWIPE_TIME
		if tap then
			if c.potential_double_tap and socket.gettime() - (c.released_time or 0) < M.DOUBLE_TAP_INTERVAL then
				c.gestures.double_tap = true
			end
			if time < M.LONG_PRESS_TIME then
				c.gestures.tap = true
				c.potential_double_tap = c.gestures.double_tap == false and true or false
			else
				c.gestures.long_press = true
				c.potential_double_tap = false
			end
		elseif swipe then
			local vertical = ay > ax
			if vertical and dy < 0 then
				c.gestures.swipe_up = true
			elseif vertical and dy > 0 then
				c.gestures.swipe_down = true
			elseif not vertical and dx < 0 then
				c.gestures.swipe_right = true
			elseif not vertical and dx > 0 then
				c.gestures.swipe_left = true
			end
			c.potential_double_tap = false
			c.gestures.swipe = {
				from = vmath.vector3(c.pressed_action.x, c.pressed_action.y, 0),
				to = vmath.vector3(action.x, action.y, 0),
				time = time,
			}
		end
		c.released_time = socket.gettime()
		c.pressed = false
	end

	return c.gestures
end

return M
