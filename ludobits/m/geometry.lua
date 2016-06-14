local M = {}


function M.to_degrees(radians)
	return radians * 180 / math.pi
end

function M.to_radians(degrees)
	return degrees * math.pi / 180
end

function M.angle_towards(from_position, to_position)
	local angle = math.atan2(to_position.x - from_position.x, from_position.y - to_position.y)
	return vmath.quat_axis_angle(vmath.vector3(0, 0, 1), angle)
end


return M
