--- Camera module to use in combination with the camera.go
--
-- Usage:
-- 1. Add the camera.go
-- 2. Select the script component on the camera.go and modify properties to suit your needs
-- 3. Optional: Use camera.screen_to_world(camera_id, x, y, z) to correctly convert screen to world coordinates for a camera

local M = {}

local projections = {}
local views = {}

local DISPLAY_WIDTH = tonumber(sys.get_config("display.width"))
local DISPLAY_HEIGHT = tonumber(sys.get_config("display.height"))
local window_width = DISPLAY_WIDTH
local window_height = DISPLAY_HEIGHT

local app = require "ludobits.m.app"
app.window.add_listener(function(self, event, data)
	if event == window.WINDOW_EVENT_RESIZED then
		window_width = data.width
		window_height = data.height
	end
end)

local orthographic_projectors = {}

orthographic_projectors[hash("DEFAULT")] = function(near_z, far_z)
	return vmath.matrix4_orthographic(0, DISPLAY_WIDTH, 0, DISPLAY_HEIGHT, near_z, far_z)
end

orthographic_projectors[hash("FIXED")] = function(near_z, far_z)
	local zoom_factor = math.min(window_width / DISPLAY_WIDTH, window_height / DISPLAY_HEIGHT)
	local projected_width = window_width / zoom_factor
	local projected_height = window_height / zoom_factor
	local xoffset = -(projected_width - DISPLAY_WIDTH) / 2
	local yoffset = -(projected_height - DISPLAY_HEIGHT) / 2
	return vmath.matrix4_orthographic(xoffset, xoffset + projected_width, yoffset, yoffset + projected_height, near_z, far_z)
end

--- Add a custom orthographic projection matrix provider
-- @param projector_id Unique id of the provider (hash)
-- @param fn The function to call when the projection matrix needs to be calculated
-- The function will receive near_z and far_z as arguments
function M.add_orthographic_projector(projector_id, fn)
	orthographic_projectors[projector_id] = fn
end

--- Get an orthographic projection matrix provider
-- @param projector_id
-- @param near_z
-- @param far_z
-- @return Projection matrix
function M.get_orthographic_projection(projector_id, near_z, far_z)
	local projector_fn = orthographic_projectors[projector_id] or orthographic_projectors[hash("DEFAULT")]
	return projector_fn(near_z, far_z)
end


--- Create an orthograpic projection matrix based on current window dimensions
-- @param near_z
-- @param far_z
function M.orthographic(near_z, far_z)
	return vmath.matrix4_orthographic(0, window_width, 0, window_height, near_z, far_z)
end

--- Get a view matrix for a specific camera, based on the camera position and rotation
-- @param camera_id
-- @return View matrix
function M.create_view_matrix(camera_id)
	local pos = go.get_world_position(camera_id)
	local rot = go.get_world_rotation(camera_id)
	
	local look_at = pos + vmath.rotate(rot, vmath.vector3(0, 0, -1.0))
	local up = vmath.rotate(rot, vmath.vector3(0, 1.0, 0))
	local view = vmath.matrix4_look_at(pos, look_at, up)
	return view
end

--- Set the projection matrix for a camera
-- @param camera_id
-- @param projection_matrix
function M.set_projection_matrix(camera_id, projection_matrix)
	projections[camera_id] = projection_matrix
end

--- Set the view matrix for a camera
-- @param camera_id
-- @param view_matrix Optional view matrix. If none is provided it will be
-- calculated based on camera position and rotation
function M.set_view_matrix(camera_id, view_matrix)
	views[camera_id] = view_matrix or M.create_view_matrix(camera_id)
end

--- Send the view and projection matrix for a camera to the render script
-- @param camera_id
function M.send_view_projection(camera_id)
	msg.post("@render:", "set_view_projection", { id = camera_id, view = views[camera_id], projection = projections[camera_id] })
end

--- Convert screen coordinates to world coordinates based
-- on a specific camera's view and projection
-- @param camera_id
-- @param x
-- @param y
-- @param z
-- http://webglfactory.blogspot.se/2011/05/how-to-convert-world-to-screen.html
function M.screen_to_world(camera_id, x, y, z)
	local v3 = vmath.vector3(x, y, 0)
	local view = views[camera_id] or vmath.matrix4()
	local proj = projections[camera_id] or M.orthographic(-1, 1)

	x = 2 * x / DISPLAY_WIDTH - 1
	y = 2 * y / DISPLAY_HEIGHT - 1
	local inv = vmath.inv(proj * view)
	local v4 = inv * vmath.vector4(x, y, 0, 1)
	return vmath.vector3(v4.x, v4.y, z)
end


return M