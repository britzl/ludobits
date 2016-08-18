local M = {}

function M.action_to_position(action)
	return vmath.vector3((M.xoffset or 0) + action.screen_x / (M.zoom_factor or 1), (M.yoffset or 0) + action.screen_y / (M.zoom_factor or 1), 0)
end

function M.set_fixed_aspect_ratio(view, x, y, width, height)
	render.set_viewport(x, y, width, height)
	render.set_view(view)
	
	-- center (and zoom out if needed)
	local original_width = render.get_width()
	local original_height = render.get_height()
	local zoom_factor = math.min(math.min(width / original_width, height / original_height), 1)
	local projected_width = width / zoom_factor
	local projected_height = height / zoom_factor
	local xoffset = -(projected_width - original_width) / 2
	local yoffset = -(projected_height - original_height) / 2
	render.set_projection(vmath.matrix4_orthographic(xoffset, xoffset + projected_width, yoffset, yoffset + projected_height, -1, 1))

	-- store zoom and offset for use when translating touch events to positions
	M.zoom_factor = zoom_factor
	M.xoffset = xoffset
	M.yoffset = yoffset
end


return M