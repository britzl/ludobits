local M = {}

local function count_orthogonal_neighbors(m, x, y, w, h)
	local count = 0
	if x == 1 or m[x - 1][y] then
		count = count + 1
	end
	if x == w or m[x + 1][y] then
		count = count + 1
	end
	if y == 1 or m[x][y - 1] then
		count = count + 1
	end
	if y == h or m[x][y + 1] then
		count = count + 1
	end
	return count
end

local function count_diagonal_neighbors(m, x, y, w, h)
	local count = 0
	-- down left
	if y == 1 or x == 1 or m[x - 1][y - 1] then
		count = count + 1
	end
	-- down right
	if y == 1 or x == w or m[x + 1][y - 1] then
		count = count + 1
	end
	-- up left
	if y == h or x == 1 or m[x - 1][y + 1] then
		count = count + 1
	end
	-- up right
	if y == h or x == w or m[x + 1][y + 1] then
		count = count + 1
	end
	return count
end

local function mutate(m, w, h, rules_fn)
	local n = {}
	for x=1,w do
		n[x] = {}
		for y=1,h do
			n[x][y] = rules_fn(m, x, y, w, h)
		end
	end
	return n
end

local function dump_map(m, w, h)
	local s = ""
	for y=h,1,-1 do
		s = s .. "\n"
		for x=1,w do
			s = s .. (m[x][y] and "#" or ".")
		end
	end
	return s
end

function M.orthogonal_only(m, x, y, w, h)
	local live = m[x][y]
	local count = count_orthogonal_neighbors(m, x, y, w, h)
	if live then
		return count == 2 or count == 3
	else
		return count == 3
	end
end


function M.all_directions(m, x, y, w, h)
	local live = m[x][y]
	local ortho_count = count_orthogonal_neighbors(m, x, y, w, h)
	local diag_count = count_diagonal_neighbors(m, x, y, w, h)
	local count = ortho_count + diag_count
	if live then
		return count >= 4
	else
		return count >= 5
	end
end


--- Generate a map using ceullular automata
-- @param w Width of map
-- @param h Height of map
-- @param fillrate How much of the map that should be live initially (0.0-1.0)
-- @param iterations The number of times the map should mutate
-- @param rules_fn How to evolve the map (one of all_directions and orthogonal_only)
-- @return Two dimensional array [x][y] with booleans
function M.generate(w, h, fillrate, iterations, rules_fn)
	assert(w and w > 0)
	assert(h and h > 0)
	fillrate = fillrate or 0.5
	iterations = iterations or 4
	rules_fn = rules_fn or M.orthogonal_only
	local m = {}

	for x=1,w do
		m[x] = {}
		for y=1,h do
			m[x][y] = math.random() <= fillrate
		end
	end

	--print(dump_map(m, w, h))

	for i=1,iterations do
		m = mutate(m, w, h, rules_fn)
		--print(dump_map(m, w, h))
	end

	return m
end


return M
