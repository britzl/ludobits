--
-- json.lua
--
-- Copyright (c) 2015 rxi
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local json = { _version = "0.1.0" }

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

local encode

local escape_char_map = {
	[ "\\" ] = "\\\\",
	[ "\"" ] = "\\\"",
	[ "\b" ] = "\\b",
	[ "\f" ] = "\\f",
	[ "\n" ] = "\\n",
	[ "\r" ] = "\\r",
	[ "\t" ] = "\\t",
}


local function escape_char(c)
	return escape_char_map[c] or string.format("\\u%04x", c:byte())
end


local function encode_nil()
	return "null"
end


local function encode_table(val, stack)
	local res = {}
	stack = stack or {}

	-- Circular reference?
	if stack[val] then error("circular reference") end

	stack[val] = true

	if val[1] ~= nil or next(val) == nil then
		-- Treat as array -- check keys are valid and it is not sparse
		local n = 0
		for k in pairs(val) do
			if type(k) ~= "number" then
				error("invalid table: mixed or invalid key types")
			end
			n = n + 1
		end
		if n ~= #val then
			error("invalid table: sparse array")
		end
		-- Encode
		for _, v in ipairs(val) do
			table.insert(res, encode(v, stack))
		end
		stack[val] = nil
		return "[" .. table.concat(res, ",") .. "]"

	else
		-- Treat as an object
		for k, v in pairs(val) do
			if type(k) ~= "string" then
				error("invalid table: mixed or invalid key types")
			end
			table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
		end
		stack[val] = nil
		return "{" .. table.concat(res, ",") .. "}"
	end
end


local function encode_string(val)
	return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end


local function encode_number(val)
	-- Check for NaN, -inf and inf
	if val ~= val or val <= -math.huge or val >= math.huge then
		error("unexpected number value '" .. tostring(val) .. "'")
	end
	return string.format("%.14g", val)
end


local type_func_map = {
	[ "nil"		 ] = encode_nil,
	[ "table"	 ] = encode_table,
	[ "string"	] = encode_string,
	[ "number"	] = encode_number,
	[ "boolean" ] = tostring,
}


encode = function(val, stack)
	local t = type(val)
	local f = type_func_map[t]
	if f then
		return f(val, stack)
	end
	error("unexpected type '" .. t .. "'")
end


function json.encode(val)
	return ( encode(val) )
end

json.decode = _G.json.decode

return json
