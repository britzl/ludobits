local M = {}


M.CONTACT_POINT_RESPONSE = hash("contact_point_response")



function M.handle_geometry_contact(correction, normal, distance, id)
	-- project the correction vector onto the contact normal
	-- (the correction vector is the 0-vector for the first contact point)
	local proj = vmath.dot(correction, normal)
	-- calculate the compensation we need to make for this contact point
	local comp = (distance - proj) * normal
	-- add it to the correction vector
	correction = correction + comp
	-- apply the compensation to the player character
	go.set_position(go.get_position(id) + comp, id)
end

--- Set rotation around z-axis in such a way that the game object is
-- facing a specific position
-- @param look_at_position The position to look at
-- @param id Optional id of the game object to rotate
function M.look_at(look_at_position, id)
	local pos = go.get_world_position(id)
	local target_angle = -math.atan2(look_at_position.x - pos.x, look_at_position.y - pos.y)
	local target_quat = vmath.quat_rotation_z(target_angle)
	go.set_rotation(target_quat, id)
end

--- Rotate around the z-axis
-- @param Amount to rotate in radians
-- @param id Optional id of the game object to rotate
function M.rotate(angle, id)
	go.set_rotation(go.get_rotation(id) * vmath.quat_rotation_z(angle), id)
end

--- Set the absolute rotation around z-axis
-- @param angle Angle in radians (use math.rad(deg) to convert from degrees to radians)
-- @param id Optional id of the game object to rotate
function M.set_rotation(angle, id)
	go.set_rotation(vmath.quat_rotation_z(angle), id)
end

--- Move forward in the current direction of rotation around z-axis
-- @param amount Distance to move
-- @param id Optional id of the game object to move
function M.forward(amount, id)
	local rotation = go.get_rotation(id)
	local direction = vmath.rotate(rotation, vmath.vector3(0, amount, 0))
	go.set_position(go.get_position(id) + direction, id)
end

--- Move backwards in the current direction of rotation around z-axis
-- @param amount Distance to move
-- @param id Optional id of the game object to move
function M.backwards(amount, id)
	local rotation = go.get_rotation(id)
	local direction = vmath.rotate(rotation, vmath.vector3(0, amount, 0))
	go.set_position(go.get_position(id) - direction, id)
end

function M.create()
	local instance = {}

	local correction = vmath.vector3()

	function instance.look_at(position)
		M.look_at(position)
	end

	function instance.set_rotation(angle)
		M.set_rotation(angle)
	end

	function instance.rotate(amount)
		M.rotate(amount)
	end

	function instance.forward(amount)
		M.forward(amount)
	end

	function instance.backwards(amount)
		M.backwards(amount)
	end

	function instance.on_message(message_id, message)
		if message_id == M.CONTACT_POINT_RESPONSE then
			M.handle_geometry_contact(correction, message.normal, message.distance)
		end
	end

	function instance.update(dt)
		correction = vmath.vector3()
	end

	return instance
end

return M
