--- Module to simplify input handling. The module will keep track of
-- pressed and released states for all input that it receives.
-- @usage
--
-- local input = require "ludobits.m.input"
-- 
-- function init(self)
-- 	input.acquire()
-- end
-- 
-- function final(self)
-- 	input.release()
-- end
-- 
-- function update(self, dt)
-- 	if input.is_pressed(hash("left")) then
-- 		go.set_position(go.get_position() - vmath.vector3(50, 0, 0) * dt)
-- 	elseif input.is_pressed(hash("right")) then
-- 		go.set_position(go.get_position() + vmath.vector3(50, 0, 0) * dt)
-- 	end
-- end
-- 
-- function on_input(self, action_id, action)
-- 	input.on_input(action_id, action)
-- end
--



local M = {}

local action_map = {}

--- Acquire input focus for the current script
-- @param url
function M.acquire(url)
	msg.post(url or ".", "acquire_input_focus")
	action_map = {}
end

--- Release input focus for the current script
-- @param url
function M.release(url)
	msg.post(url or ".", "release_input_focus")
	action_map = {}
end

--- Check if an action is pressed/active
-- @param action_id
-- @return true if pressed/active
function M.is_pressed(action_id)
	assert(action_id, "You must provide an action_id")
	action_id = type(action_id) == "string" and hash(action_id) or action_id
	return action_map[action_id]
end

--- Forward any calls to on_input from scripts using this module
-- @param action_id
-- @param action
function M.update(action_id, action)
	assert(action, "You must provide an action")
	if action_id then
		action_id = type(action_id) == "string" and hash(action_id) or action_id
		if action.pressed then
			action_map[action_id] = true
		elseif action.released then
			action_map[action_id] = false
		end
	end
end
function M.on_input(action_id, action)
	-- I can't decide on which I like best, on_input() or update()
	M.update(action_id, action)
end

return M
