local M = {}


function M.to_degrees(radians)
	return radians * 180 / math.pi
end

function M.to_radians(degrees)
	return degrees * math.pi / 180
end


return M
