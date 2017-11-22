local M = {}


function M.lerp(a, b, t)
	return a + (b - a) * t
end


function M.shuffle(t)
	local size = #t
	for i = size, 1, -1 do
		local rand = math.random(size)
		t[i], t[rand] = t[rand], t[i]
	end
	return t
end


function M.random(list)
	return list[math.random(1, #list)]
end

return M
