local M = {}

local threads = {}

local id = 0

local handle = nil

local function start_timer()
	if handle then
		return
	end
	handle = timer.delay(0, true, function(self, handle, dt)
		for id, thread in pairs(threads) do
			if thread.cancelled then
				threads[id] = nil
			else
				local status = coroutine.status(thread.co)
				if status == "suspended" then
					local ok, result = coroutine.resume(thread.co)
					if not ok then
						threads[id] = nil
						pcall(thread.cb, false, result)
					end
				elseif status == "dead" then
					threads[id] = nil
					pcall(thread.cb, true, thread.result)
				end
			end
		end

		if not next(threads) then
			timer.cancel(handle)
			handle = nil
		end
	end)
end

function M.create(fn, cb)
	assert(fn, "You must provide a function to run")
	assert(cb, "You must provide a result callback")
	id = id + 1
	local thread = {
		id = id,
		cb = cb,
	}
	thread.co = coroutine.create(function()
		local ok, result = pcall(fn, coroutine.yield)
		if not ok then
			pcall(cb, false, result)
		else
			thread.result = result
		end
	end)
	threads[id] = thread

	local ok, result = coroutine.resume(thread.co)
	if not ok then
		threads[id] = nil
		pcall(cb, false, result)
		return id
	end

	start_timer()

	return id
end


function M.cancel(id)
	local t = threads[id]
	assert(t)
	t.cancelled = true
end


return M