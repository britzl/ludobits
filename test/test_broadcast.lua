local mock = require "deftest.mock.mock"

return function()
	local broadcast = require "ludobits.m.broadcast"
	
	describe("broadcast", function()
		before(function()
			mock.mock(msg)
			msg.post.replace(function() end)
		end)

		after(function()
			mock.unmock(msg)
		end)

		-- the broadcast1 and broadcast2 game objects are completely empty and they exist in the test.collection
		it("should post a message to each registered recipient", function()
			msg.url.returns({ msg.url("broadcast1"), msg.url("broadcast2") })
			broadcast.register("foo")
			broadcast.register("foo")

			msg.url.returns({ msg.url("broadcast1"), msg.url("broadcast2") })
			broadcast.register("bar")
			broadcast.register("bar")

			broadcast.send("foo")
			assert(msg.post.calls == 2, "Expected 2 calls")
		end)
		
		it("should not send a message to an unregistered recipient", function()
			msg.url.returns({ msg.url("broadcast1"), msg.url("broadcast2") })
			broadcast.register("foo")
			broadcast.register("foo")

			broadcast.send("foo")
			assert(msg.post.calls == 2, "Expected 2 calls")

			msg.url.returns({ msg.url("broadcast1") })
			broadcast.unregister("foo")
			
			broadcast.send("foo")
			assert(msg.post.calls == 3, "Expected 3 calls")			
		end)
		
		it("should be possible to register a message handler function", function()
			local message_handler_called = false
			msg.url.returns({ msg.url("broadcast1"), msg.url("broadcast2") })
			broadcast.register("foo", function()
				message_handler_called = true
			end)
			broadcast.register("foo")

			msg.url.returns({ msg.url("broadcast2") })
			broadcast.on_message(hash("foo"), {})
			assert(not message_handler_called)

			msg.url.returns({ msg.url("broadcast1") })
			broadcast.on_message(hash("foo"), {})
			assert(message_handler_called)
		end)
	end)
end