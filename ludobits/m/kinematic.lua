local geometry = require "ludobits.m.geometry"

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
--[[	-- project the velocity onto the normal
	proj = vmath.dot(self.velocity, normal)
	-- if the projection is negative, it means that some of the velocity points towards the contact point
	if proj < 0 then
		-- remove that component in that case
		self.velocity = self.velocity - proj * normal
	end--]]
end

function M.look_at(destination, id)
	local quat_angle = geometry.angle_towards(go.get_position(id), destination)
	go.set_rotation(quat_angle)
	return angle
end

function M.rotate(angle, id)
	go.set_rotation(go.get_rotation(id) + vmath.quat_axis_angle(vmath.vector3(0, 0, 1), angle), id)
end

function M.set_rotation(angle, id)
	go.set_rotation(vmath.quat_axis_angle(vmath.vector3(0, 0, 1), angle), id)
end

function M.forward(angle, amount, id)
	go.set_position(go.get_position(id) + vmath.vector3(-math.sin(angle) * amount, math.cos(angle) * amount, 0), id)
end

function M.backwards(angle, amount, id)
	go.set_position(go.get_position(id) + vmath.vector3(math.sin(angle) * amount, -math.cos(angle) * amount, 0), id)
end

function M.create()
	local instance = {
		angle = 0 -- radians
	}

	local correction = vmath.vector3()

	function instance.look_at(destination)
		local radians = M.look_at(destination)
		instance.angle = geometry.to_radians((180 + geometry.to_degrees(radians)) % 360)
	end

	function instance.set_rotation(angle)
		M.set_rotation(angle)
		instance.angle = angle
	end

	function instance.rotate(amount)
		instance.angle = instance.angle + amount
		M.set_rotation(instance.angle)
	end

	function instance.forward(amount)
		M.forward(instance.angle, amount)
	end

	function instance.backwards(amount)
		M.backwards(instance.angle, amount)
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
