local mock = require "deftest.mock.mock"
local unload = require "deftest.util.unload"

local function wait_until(cb)
	local co = coroutine.running()
	timer.delay(0.01, true, function(self, handle, elapsed_time)
		if cb() then
			timer.cancel(handle)
			coroutine.resume(co)
		end
	end)
	coroutine.yield()
end

local function wait_seconds(seconds)
	local co = coroutine.running()
	timer.delay(seconds, false, function(self, handle, elapsed_time)
		coroutine.resume(co)
	end)
	coroutine.yield()
end

return function()
	local flow
	
	local MSG_RESUME = hash("FLOW_RESUME")
	local broadcast1 = msg.url("broadcast1")
	local broadcast2 = msg.url("broadcast2")
	
	describe("flow", function()
		before(function()
			unload.unload("ludobits.")
			flow = require "ludobits.m.flow"
			mock.mock(msg)
			msg.post.replace(function(url, message_id, message, sender)
				flow.on_message(type(message_id) == "string" and hash(message_id) or message_id, message, sender)
			end)
		end)

		after(function()
			mock.unmock(msg)
			package.loaded["ludobits.m.flow"] = nil
		end)

		it("should return a reference to the flow when started", function()
			local instance = flow.start(function() end)
			assert(instance)
		end)

		it("should run the flow immediately when started", function()
			local flow_finished = false
			flow.start(function()
				flow_finished = true
			end)
			assert(flow_finished)
		end)

		it("should run the flow on a timer", function()
			msg.url.replace(function() return broadcast1 end)

			local flow_finished = false
			local instance = flow.start(function()
				flow_finished = true
			end)

			wait_until(function()
				return flow_finished
			end)

			assert(flow_finished)
		end)
		
		it("should be able to pause for a specific number of seconds", function()
			msg.url.replace(function() return broadcast1 end)

			local flow_finished = false
			local instance = flow.start(function()
				flow.delay(1)
				flow_finished = true
			end)
			wait_seconds(0.5)
			assert(not flow_finished)
			
			wait_seconds(0.75)
			assert(flow_finished)
		end)
		
		it("should be able to pause for a specific number of frames", function()
			msg.url.replace(function() return broadcast1 end)

			local flow_finished = false
			local instance = flow.start(function()
				flow.frames(20)
				flow_finished = true
			end)

			wait_seconds(20 * 0.02)
			assert(flow_finished)
		end)

		it("should be able to pause until a condition is true", function()
			msg.url.replace(function() return broadcast1 end)

			local flow_finished = false
			local is_it_true_yet = false
			local instance = flow.start(function()
				flow.until_true(function()
					return is_it_true_yet
				end)
				flow_finished = true
			end)

			wait_seconds(0.25)
			assert(not flow_finished)
			is_it_true_yet = true
			wait_seconds(0.25)
			assert(flow_finished)
		end)

		it("should be able to pause until a message is received", function()
			msg.url.replace(function() return broadcast1 end)

			local flow_finished = false
			local instance = flow.start(function()
				flow.until_any_message()
				flow_finished = true
			end)

			wait_seconds(0.25)
			assert(not flow_finished)
			msg.post(broadcast1, "foobar", {})
			wait_seconds(0.25)
			assert(flow_finished)
		end)

		it("should be able to pause until a specific message is received", function()
			msg.url.replace(function() return broadcast1 end)

			local flow_finished = false
			local instance = flow.start(function()
				flow.until_message("foo", "bar")
				flow.until_message("boo", "car")
				flow_finished = true
			end)

			wait_seconds(0.25)
			assert(not flow_finished)

			msg.post(broadcast1, "bar", {})
			wait_seconds(0.25)
			assert(not flow_finished)
			msg.post(broadcast1, "boo", {})
			wait_seconds(0.25)
			assert(flow_finished)
		end)
		
		it("should be possible to pause until a callback is invoked", function()
			msg.url.replace(function() return broadcast1 end)

			local callback
			local flow_finished = false
			local instance = flow.start(function()
				flow.until_callback(function(cb, foo, bar)
					assert(foo == "foo")
					assert(bar == "bar")
					callback = cb
				end, "foo", "bar")
				flow_finished = true
			end)

			wait_seconds(0.25)
			assert(not flow_finished)

			callback()
			wait_seconds(0.25)
			assert(flow_finished)
		end)

		it("should be possible to pause until flows complete", function()
			local flow_finished = false
			local instance = flow.start(function()
				local f1 = flow.parallel(function()
					flow.delay(0.3)
				end)

				local f2 = flow.parallel(function()
					flow.delay(0.3)
				end)

				flow.until_flows(f1)
				flow.until_flows({ f1, f2 })
				flow_finished = true
			end)

			wait_seconds(0.2)
			assert(not flow_finished)

			wait_seconds(0.2)
			assert(flow_finished)
		end)
	end)
end