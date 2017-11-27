--- Create bezier curves
local M = {}


local function point_on_cubic_bezier(cp, t)
	local ax, bx, cx
	local ay, by, cy
	local tSquared, tCubed

	--  /* calculation of the polinomial coeficients */

	cx = 3.0 * (cp[2].x - cp[1].x)
	bx = 3.0 * (cp[1].x - cp[2].x) - cx
	ax = cp[4].x - cp[1].x - cx - bx

	cy = 3.0 * (cp[2].y - cp[1].y)
	by = 3.0 * (cp[3].y - cp[2].y) - cy
	ay = cp[4].y - cp[1].y - cy - by

	--  /* calculate the curve point at parameter value t */

	tSquared = t * t
	tCubed = tSquared * t

	local result = vmath.vector3()
	result.x = (ax * tCubed) + (bx * tSquared) + (cx * t) + cp[1].x
	result.y = (ay * tCubed) + (by * tSquared) + (cy * t) + cp[1].y
	return result
end

--- Create a bezier curve
-- @param cp Table with control points (pairs of { x, y })
-- @param points The number of points to generate along the curve
-- @return Table with all of the vmath.vector3() points along the curve
function M.create(cp, points)
	local curve = {}
	local dt = 1.0 / (points - 1)
	local i

	for i = 1, points do
		curve[i] = point_on_cubic_bezier(cp, i * dt)
		i = i + 1
	end
	return curve
end

return M
