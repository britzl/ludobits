local M = {}

function M.angle_towards(from, to)
	local angle = math.atan2(to.x - from.x, from.y - to.y)
	return vmath.quat_axis_angle(vmath.vector3(0, 0, 1), angle)
end

function M.distance(from, to)
	return math.sqrt(math.abs(from.x - to.x) ^ 2 + math.abs(from.y - to.y) ^ 2)
end

return M
