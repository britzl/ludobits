# Thread
Module to wrap and run a long-running task over multiple frames using coroutines

## Usage

```lua
local thread = require "ludobits.m.thread"

-- long-running task
-- call pause frequently to hand over execution to the engine
-- the task will be resumed the next frame again
local function do_long_running_task(pause)
	local numbers = {}
	for i=1,100 do
		numbers[#numbers+1] = math.random()
		pause()
	end
	return numbers
end

function init(self)
	-- create a new thread
	-- run the long-running task until it completes at which point it will
	-- invoke the provided callback
	local handle = thread.create(do_long_running_task, function(ok, numbers)
		print(ok) -- true if long-running task completed without errors
		pprint(numbers) -- the return value from the task or an error message
	end)

	-- call thread.cancel() to stop task early
	thread.cancel(handle)
end
```