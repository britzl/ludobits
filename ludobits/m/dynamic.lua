local M = {}

local LINEAR_VELOCITY = hash("linear_velocity")
local ANGULAR_VELOCITY = hash("angular_velocity")

function M.rotate(collisionobject_url, force)
	local rotation = go.get_rotation()
	local world_position = go.get_world_position()
	msg.post(collisionobject_url, "apply_force", { force = vmath.rotate(rotation, force), position = world_position + vmath.rotate(rotation, vmath.vector3(-50, 50, 0)) })
	msg.post(collisionobject_url, "apply_force", { force = vmath.rotate(rotation, -force), position = world_position + vmath.rotate(rotation, vmath.vector3(50, -50, 0)) })
end


---
-- @param collisionobject_url
-- @param force In the format of vmath.vector3(0, force, 0)
function M.forward(collisionobject_url, force)
	msg.post(collisionobject_url, "apply_force", { force = vmath.rotate(go.get_rotation(), force), position = go.get_world_position() })
end

---
-- @param collisionobject_url
-- @param force In the format of vmath.vector3(0, force, 0)
function M.backwards(collisionobject_url, force)
	msg.post(collisionobject_url, "apply_force", { force = vmath.rotate(go.get_rotation(), -force), position = go.get_world_position() })
end

function M.stop_moving(collisionobject_url)
	msg.post(collisionobject_url, "apply_force", { force = -go.get(collisionobject_url, LINEAR_VELOCITY) * 10, position = go.get_world_position() })
end

function M.stop_rotating(collisionobject_url)
	local angv = go.get(collisionobject_url, ANGULAR_VELOCITY)
	angv.x = angv.z
	angv.z = 0
	M.rotate(collisionobject_url, angv * 100)
end

return M