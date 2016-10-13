local mock = require "deftest.mock"

return function()
	local flow
	
	local MSG_RESUME = hash("FLOW_RESUME")
	
	describe("flow", function()
		before(function()
			flow = require "ludobits.m.flow"
			mock.mock(msg)
			msg.post.replace(function() end)
		end)

		after(function()
			mock.unmock(msg)
			package.loaded["ludobits.m.flow"] = nil
		end)

		it("should return a reference to the flow when started", function()
			local instance = flow.start(function() end)
			assert(instance)
		end)

		it("should not run the flow immediately when started", function()
			local flow_finished = false
			flow.start(function()
				flow_finished = true
			end)
			assert(not flow_finished)
		end)

		it("should run the flow after a call to update", function()
			msg.url.replace(function() return msg.url.original("broadcast1") end)
			msg.post.replace(function(url, message_id, message, sender)
				flow.on_message(message_id, message, sender)
			end)

			local flow_finished = false
			local instance = flow.start(function()
				flow_finished = true
			end)

			flow.update(0)

			assert(flow_finished)
		end)
		
		it("should be able to pause for a specific number of seconds", function()
			msg.url.replace(function() return msg.url.original("broadcast1") end)
			msg.post.replace(function(url, message_id, message, sender)
				flow.on_message(message_id, message, sender)
			end)

			local flow_finished = false
			local instance = flow.start(function()
				flow.delay(20)
				flow_finished = true
			end)

			flow.update(0)
			flow.update(19)
			assert(not flow_finished)
			
			flow.update(1)
			assert(flow_finished)
		end)
		
		it("should be able to pause for a specific number of frames", function()
			msg.url.replace(function() return msg.url.original("broadcast1") end)
			msg.post.replace(function(url, message_id, message, sender)
				flow.on_message(message_id, message, sender)
			end)

			local flow_finished = false
			local instance = flow.start(function()
				flow.frames(20)
				flow_finished = true
			end)

			flow.update(0)
			for i=1,19 do
				flow.update(1)
				assert(not flow_finished)
			end
			
			flow.update(1)
			assert(flow_finished)
		end)
		
		it("should be able to pause until a condition is true", function()
			local broadcast1 = msg.url("broadcast1")
			msg.url.replace(function() return broadcast1 end)
			msg.post.replace(function(url, message_id, message, sender)
				flow.on_message(message_id, message, sender)
			end)

			local flow_finished = false
			local is_it_true_yet = false
			local instance = flow.start(function()
				flow.until_true(function()
					return is_it_true_yet == true
				end)
				flow_finished = true
			end)

			for i=1,10 do
				flow.update(i)
				assert(not flow_finished)
			end
			is_it_true_yet = true
			
			flow.update(1)
			assert(flow_finished)
		end)
	end)
end