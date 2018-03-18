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

	local state = {
		current = {},
		previous = {},
	}

	local instance = {
		velocity = vmath.vector3(),
		gravity = -100,
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

	-- Move the game object up by setting vertical velocity
	-- @param velocity Vertical velocity
	function instance.up(velocity)
		instance.velocity.y = velocity
	end

	--- Move the game object down by setting vertical velocity
	-- @param velocity Vertical velocity
	function instance.down(velocity)
		instance.velocity.y = -velocity
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
		if state.current.ground_contact then
			instance.velocity.y = power
			state.current.jumping = true
		elseif state.current.wall_contact and allow_wall_jump then
			instance.velocity.y = power * 0.75
			instance.velocity.x = state.current.wall_contact.x * power * 0.35
			state.current.jumping = true
			state.current.wall_jumping = true
		elseif allow_double_jump and jumping_up() and not state.current.double_jumping then
			instance.velocity.y = instance.velocity.y + power
			state.current.double_jumping = true
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
		return state.current.jumping
	end

	--- Check if this object is falling
	-- @return true if falling
	function instance.is_falling()
		return not state.current.ground_contact and not state.previous.ground_contact and not jumping_up()
	end

	--- Check if this object has contact with the ground
	-- @return true if ground contact
	function instance.has_ground_contact()
		return state.current.ground_contact and state.previous.ground_contact
	end

	--- Check if this object has contact with a wall
	-- @return true if wall contact
	function instance.has_wall_contact()
		return state.current.wall_contact and state.previous.wall_contact
	end
	
	--- Forward any on_message calls here to resolve physics collisions
	-- @param message_id
	-- @param message
	function instance.on_message(message_id, message)
		if message_id == CONTACT_POINT_RESPONSE then
			if collision_hashes[message.group] then
				-- separate collision objects and adjust velocity
				local proj = vmath.dot(correction, message.normal)
				local comp = (message.distance - proj) * message.normal
				correction = correction + comp
				go.set_position(go.get_position() + comp)
				proj = vmath.dot(instance.velocity, message.normal)
				if proj < 0 then
					instance.velocity = instance.velocity - proj * message.normal
				end
				instance.normal = message.normal

				-- check wall contact
				if math.abs(message.normal.x) > 0.8 then
					state.current.wall_contact = message.normal
				end
				-- check ground contact
				if message.normal.y > 0 then
					state.current.ground_contact = message.normal
					state.current.jumping = false
					state.current.double_jumping = false
					state.current.wall_jumping = false
					msg.post(".", "set_parent", { parent_id = message.other_id })
				end
			end
		end
	end

	--- Call this every frame to update the platformer physics
	-- @param dt
	function instance.update(dt)
		-- update velocity and move the game object
		instance.velocity.y = instance.velocity.y + instance.gravity * dt
		local pos = go.get_position()
		local new_pos = pos + instance.velocity * dt
		go.set_position(new_pos)

		-- notify game object of ground contact
		local ground_contact = instance.has_ground_contact()
		if not instance.ground_contact and ground_contact then
			msg.post("#", "ground_contact")
		elseif instance.ground_contact and not ground_contact then
			msg.post("#", "airborne")
		end
		instance.ground_contact = ground_contact

		-- notify game object of wall contact
		local wall_contact = instance.has_wall_contact()
		if not instance.wall_contact and wall_contact then
			msg.post("#", "wall_contact")
		end
		instance.wall_contact = wall_contact

		-- detach from parent if airborne
		if not state.current.ground_contact then
			msg.post(".", "set_parent", { parent_id = nil })
		end

		-- reset transient state
		correction = vmath.vector3()
		state.previous, state.current = state.current, state.previous
		state.current.ground_contact = false
		state.current.wall_contact = false
	end

	return instance
end

return M
