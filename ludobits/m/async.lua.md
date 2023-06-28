## Co-routine wrapper for asynchronous operations

Usage:

```lua
local async = require("ludobits.m.async")

local co = coroutine.create(function()
  -- do an http request and wait for the response
  local response = async.http_request("https://www.foobar.com", "GET", headers)
  print(response.code)

  -- animate a game object over time and wait until completed
  local to = vmath.vector3(100, 100, 0)
  local duration = 5 -- seconds
  local delay = 1 -- second
  async.go_animate(".", "position", go.PLAYBACK_ONCE_FORWARD, to, go.EASING_LINEAR, duration, delay)

  -- wait 5 seconds
  async.delay(5)

  print("We're done!)
end)
coroutine.resume(co)
```
