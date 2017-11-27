--- Wrapper for the physics and behaviour involved in creating a platformer
-- game

local M = {}

local CONTACT_POINT_RESPONSE = hash("contact_point_response")

--- Create a platformer game logic wrapper. This will provide all the functionality
-- to control a game object in a platformer game. The functions will operate on
-- the game object attached to the script calling the functions.
-- @param collision_hashes Table with hashes for the collision groups that
-- prevents movement and where collisions should be resolved
function M.create(collision_hashes)
	collision_hashes = collision_hashes or {}
	for _,h in ipairs(collision_hashes) do
		collision_hashes[h] = true
	end

	local instance = {
		velocity = vmath.vector3(),
		gravity = -100,
		ground_contact = false,
		wall_contact = false,
		jumping = false,
		double_jumping = false,
	}

	local correction = vmath.vector3()

	local function jumping_up()
		return (instance.velocity.y > 0 and instance.gravity < 0) or (instance.velocity.y < 0 and instance.gravity > 0)
	end

	-- Move the game object left by setting horizontal velocity
	-- @param velocity Horizontal velocity
	function instance.left(velocity)
		instance.velocity.x = -velocity
	end

	--- Move the game object right by setting horizontal velocity
	-- @param velocity Horizontal velocity
	function instance.right(velocity)
		instance.velocity.x = velocity
	end

	--- Move the game object by setting its velocity
	-- @param velocity Velocity as a vector3
	function instance.move(velocity)
		instance.velocity = velocity
	end

	--- Stop horizontal movement by setting the velocity.x component to zero
	function instance.stop()
		instance.velocity.x = 0
	end

	--- Try to make the game object jump.
	-- @param power The power of the jump (ie how high)
	-- @param allow_double_jump True if double-jump should be allowed
	-- @param allow_wall_jump True if wall-jump should be allowed
	function instance.jump(power, allow_double_jump, allow_wall_jump)
		if instance.ground_contact then
			instance.velocity.y = power
			instance.jumping = true
		elseif instance.wall_contact and allow_wall_jump then
			instance.velocity.y = power * 0.75
			instance.velocity.x = instance.wall_contact.x * power * 0.35
			instance.jumping = true
			instance.wall_jumping = true
		elseif allow_double_jump and jumping_up() and not instance.double_jumping then
			instance.velocity.y = instance.velocity.y + power
			instance.double_jumping = true
		end
	end

	--- Abort a jump by "cutting it short"
	-- @param reduction The amount to reduce the vertical speed (default 0.5)
	function instance.abort_jump(reduction)
		if jumping_up() then
			instance.velocity.y = instance.velocity.y * (reduction or 0.5)
		end
	end

	--- Check if this object is jumping
	-- @return true if jumping
	function instance.is_jumping()
		return instance.jumping
	end

	--- Check if this object is falling
	-- @return true if falling
	function instance.is_falling()
		return not instance.ground_contact and not jumping_up()
	end

	--- Forward any on_message calls here to resolve physics collisions
	-- @param message_id
	-- @param message
	function instance.on_message(message_id, message)
		if message_id == CONTACT_POINT_RESPONSE then
			if collision_hashes[message.group] then
				local proj = vmath.dot(correction, message.normal)
				local comp = (message.distance - proj) * message.normal
				correction = correction + comp
				go.set_position(go.get_position() + comp)
				proj = vmath.dot(instance.velocity, message.normal)
				if proj < 0 then
					instance.velocity = instance.velocity - proj * message.normal
				end
				instance.wall_contact = math.abs(message.normal.x) > 0.8 and message.normal or instance.wall_contact
				instance.ground_contact = message.normal.y ~= 0 and message.normal or instance.ground_contact
				if message.normal.y ~= 0 then
					instance.jumping = false
					instance.double_jumping = false
					instance.wall_jumping = false
				end
			end
		end
	end

	--- Call this every frame to update the platformer physics
	-- @param dt
	function instance.update(dt)
		instance.velocity.y = instance.velocity.y + instance.gravity * dt
		local pos = go.get_position()
		go.set_position(pos + instance.velocity * dt)

		correction = vmath.vector3()
		instance.ground_contact = false
		instance.wall_contact = false
	end

	return instance
end

return M
