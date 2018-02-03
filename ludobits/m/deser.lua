local json = require "ludobits.m.json"

local M = {}

local function v3_to_t(v3) return { x = v3.x, y = v3.y, z = v3.z } end
local function t_to_v3(t) return vmath.vector3(t.x, t.y, t.z) end
local function v4_to_t(v4) return { x = v4.x, y = v4.y, z = v4.z, w = v4.w } end
local function t_to_v4(t) return vmath.vector4(t.x, t.y, t.z, t.w) end
local function quat_to_t(q) return { x = q.x, y = q.y, z = q.z, w = q.w } end
local function t_to_quat(t) return vmath.quat(t.x, t.y, t.z, t.w) end

M.copy = {
	encode = function(v) return v end,
	decode = function(v) return v end
}

M.ignore = {
	encode = function(v) return nil end,
	decode = function(v) return nil end,
}

M.vector3 = {
	encode = function(v3)
		if not v3 then
			return nil
		else
			assert(type(v3) == "userdata", "Expected userdata")
			assert(v3.x and v3.y and v3.z, "Expected a vector 3")
			return v3_to_t(v3)
		end
	end,
	decode = function(t)
		if not t then
			return nil
		else
			assert(type(t) == "table", "Expected a table")
			assert(t.x and t.y and t.z, "Expected table to have x, y and z components")
			return t_to_v3(t)
		end
	end
}

M.vector4 = {
	encode = function(v4)
		if not v4 then
			return nil
		else
			assert(type(v4) == "userdata", "Expected userdata")
			assert(v4.x and v4.y and v4.z and v4.w, "Expected userdata to have x, y, z and w components")
			return v4_to_t(v4)
		end
	end,
	decode = function(t)
		if not t then
			return nil
		else
			assert(type(t) == "table", "Expected a table")
			assert(t.x and t.y and t.z and t.w)
			return t_to_v4(t)
		end
	end
}

M.quat = {
	encode = function(q)
		if not q then
			return nil
		else
			assert(type(q) == "userdata", "Expected userdata")
			assert(q.x and q.y and q.z and q.w, "Expected userdata to have x, y, z and w components")
			return quat_to_t(q)
		end
	end,
	decode = function(t)
		if not t then
			return nil
		else
			assert(type(t) == "table", "Expected a table")
			assert(t.x and t.y and t.z and t.w, "Expected table to have x, y, z and w components")
			return t_to_quat(t)
		end
	end
}

M.func = function(fn)
	assert(fn and type(fn) == "function", "You must provide a function")
	return {
		encode = function(v) return "" end,
		decode = function(v) return fn end,
	}
end

M.gameobject = function(factory_url, properties)
	assert(factory_url, "You must provide a factory url")
	return {
		encode = function(id)
			assert(id and type(id) == "userdata", "Expected userdata")
			local props = {}
			for script,script_props in pairs(properties) do
				props[script] = {}
				for key,fn in pairs(script_props) do
					local url = msg.url(nil, id, script)
					local value = go.get(url, key)
					props[script][key] = fn.encode(value)
				end
			end
			return {
				pos = v3_to_t(go.get_position(id)),
				rot = quat_to_t(go.get_rotation(id)),
				scale = v3_to_t(go.get_scale(id)),
				properties = props,
			}
		end,
		decode = function(t)
			assert(t and type(t) == "table", "Expected a table")
			local pos = t_to_v3(t.pos)
			local rot = t_to_quat(t.rot)
			local scale = t_to_v3(t.scale)
			local id = factory.create(factory_url, pos, rot, {}, scale)

			for script,script_props in pairs(properties) do
				for key,fn in pairs(script_props) do
					local value = fn.decode(t.properties[script][key])
					go.set(msg.url(nil, id, script), key, value)
				end
			end

			return id
		end
	}
end

function M.tableof(fn)
	assert(fn and fn.encode and fn.decode, "Expected an encodable type")
	return {
		encode = function(t)
			local res = {}
			for k,v in pairs(t) do
				res[k] = fn.encode(v)
			end
			return res
		end,
		decode = function(t)
			local res = {}
			for k,v in pairs(t) do
				res[k] = fn.decode(v)
			end
			return res
		end
	}
end

function M.object(model)
	assert(model and type(mode) == "table", "Expected an object model")
	return {
		encode = function(data)
			local result = {}
			for k,v in pairs(data) do
				if model[k] then
					result[k] = model[k].encode(v)
				else
					result[k] = v
				end
			end
			return result
		end,
		decode = function(data)
			local result = {}
			for k,v in pairs(data) do
				if model[k] then
					result[k] = model[k].decode(v)
				else
					result[k] = v
				end
			end
			return result
		end
	}
end

function M.json(model)
	assert(model)
	return {
		encode = function(v)
			return json.encode(model.encode(v))
		end,
		decode = function(v)
			return model.decode(json.decode(v))
		end
	}
end


return  M