--- Module to simplify input handling. The module will keep track of
-- pressed and released states for all input that it receives.

local M = {}

local action_map = {}

--- Acquire input focus for the current script
function M.acquire()
	msg.post(".", "acquire_input_focus")
	action_map = {}
end

--- Release input focus for the current script
function M.release()
	msg.post(".", "release_input_focus")
	action_map = {}
end

--- Check if an action is pressed/active
-- @param action_id
-- @return true if pressed/active
function M.is_pressed(action_id)
	assert(action_id, "You must provide an action_id")
	action_id = type(action_id) == "string" and hash(action_id) or action_id
	return action_map[hash_to_hex(action_id)]
end

--- Forward any calls to on_input from scripts using this module
function M.update(action_id, action)
	assert(action, "You must provide an action")
	if action_id then
		action_id = type(action_id) == "string" and hash(action_id) or action_id
		if action.pressed then
			action_map[hash_to_hex(action_id)] = true
		elseif action.released then
			action_map[hash_to_hex(action_id)] = false
		end
	end
end

return M