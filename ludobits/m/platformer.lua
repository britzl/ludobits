local M = {}

local CONTACT_POINT_RESPONSE = hash("contact_point_response")


function M.create(collision_hashes)
	for _,h in ipairs(collision_hashes) do
		collision_hashes[h] = true
	end
	
	local instance = {
		velocity = vmath.vector3(),
		gravity = -100,
		ground_contact = false,
	}

	local correction = vmath.vector3()
	local double_jumping = false
	
	local function jumping_up()
		return (instance.velocity.y > 0 and instance.gravity < 0) or (instance.velocity.y < 0 and instance.gravity > 0)
	end
	
	function instance.left(velocity)
		instance.velocity.x = -velocity
	end
	
	function instance.right(velocity)
		instance.velocity.x = velocity
	end
	
	function instance.stop()
		instance.velocity.x = 0
	end
	
	function instance.jump(power, allow_double_jump)
		if instance.ground_contact then
			instance.velocity.y = instance.velocity.y + power
		elseif allow_double_jump and jumping_up() and not double_jumping then
			instance.velocity.y = instance.velocity.y + power
			double_jumping = true
		end
	end
	
	function instance.abort_jump()
		if jumping_up() then
			instance.velocity.y = instance.velocity.y * 0.5
		end
	end

	function instance.on_message(message_id, message)
		if message_id == CONTACT_POINT_RESPONSE then
			if collision_hashes[message.group] then
				local proj = vmath.dot(correction, message.normal)
				local comp = (message.distance - proj) * message.normal
				correction = correction + comp
				go.set_position(go.get_position(id) + comp)
				proj = vmath.dot(instance.velocity, message.normal)
				if proj < 0 then
					instance.velocity = instance.velocity - proj * message.normal
				end
				instance.ground_contact = true
				double_jumping = false
			end
		end
	end

	function instance.update(dt)
		instance.velocity.y = instance.velocity.y + instance.gravity * dt
		local pos = go.get_position()
		go.set_position(pos + instance.velocity * dt)
	
		correction = vmath.vector3()
		instance.ground_contact = false
	end

	return instance
end

return M
