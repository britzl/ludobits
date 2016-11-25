local M = {}

local LINEAR_VELOCITY = hash("linear_velocity")
local ANGULAR_VELOCITY = hash("angular_velocity")
local MASS = hash("mass")

--- Rotate a collision object be applying opposing and offset forces
-- @param collisionobject_url
-- @param force In the format of vmath.vector3(0, force, 0)
function M.rotate(collisionobject_url, force)
	local mass = go.get(collisionobject_url, MASS)
	local rotation = go.get_rotation()
	local world_position = go.get_world_position()
	msg.post(collisionobject_url, "apply_force", { force = vmath.rotate(rotation, force * mass), position = world_position + vmath.rotate(rotation, vmath.vector3(-50, 50, 0)) })
	msg.post(collisionobject_url, "apply_force", { force = vmath.rotate(rotation, -force * mass), position = world_position + vmath.rotate(rotation, vmath.vector3(50, -50, 0)) })
end


--- Move a dynamic collision object in its direction of rotation by
-- applying a force 
-- @param collisionobject_url
-- @param force In the format of vmath.vector3(0, force, 0)
function M.forward(collisionobject_url, force)
	local mass = go.get(collisionobject_url, MASS)
	msg.post(collisionobject_url, "apply_force", { force = vmath.rotate(go.get_rotation(), force * mass), position = go.get_world_position() })
end

--- Move a dynamic collision object in the opposite direction of
-- its rotation by applying a force 
-- @param collisionobject_url
-- @param force In the format of vmath.vector3(0, force, 0)
function M.backwards(collisionobject_url, force)
	local mass = go.get(collisionobject_url, MASS)
	msg.post(collisionobject_url, "apply_force", { force = vmath.rotate(go.get_rotation(), -force * mass), position = go.get_world_position() })
end

function M.stop_moving(collisionobject_url)
	local mass = go.get(collisionobject_url, MASS)
	local linv = go.get(collisionobject_url, LINEAR_VELOCITY)
	msg.post(collisionobject_url, "apply_force", { force = -linv * 100 * mass, position = go.get_world_position() })
end

function M.stop_rotating(collisionobject_url)
	local angv = go.get(collisionobject_url, ANGULAR_VELOCITY)
	angv.x = angv.z
	angv.z = 0
	M.rotate(collisionobject_url, angv * 100)
end

return M