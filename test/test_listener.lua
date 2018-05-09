local mock = require "deftest.mock.mock"
local unload = require "deftest.util.unload"

return function()
	local listener
	
	describe("listener", function()
		before(function()
			unload.unload("ludobits.")
			listener = require "ludobits.m.listener"
			mock.mock(msg)
			msg.post.replace(function() end)
		end)

		after(function()
			mock.unmock(msg)
			package.loaded["ludobits.m.listener"] = nil
		end)

		it("should be able to create multiple listeners", function()
			local l1 = listener.create()
			local l2 = listener.create()
			assert(l1)
			assert(l2)
			assert(l1 ~= l2)
		end)

		it("should be able to add listeners as functions and trigger them", function()
			local t = {
				fn1 = function() end,
				fn2 = function() end,
				fn3 = function() end,
			}
			mock.mock(t)

			local l1 = listener.create()
			local l2 = listener.create()
			l1.add(t.fn1)
			l1.add(t.fn2)
			l2.add(t.fn1)
			l2.add(t.fn3)
			
			l1.trigger("message_id1")
			assert(t.fn1.calls == 1)
			assert(t.fn2.calls == 1)
			assert(t.fn3.calls == 0)
			assert(t.fn1.params[1] == hash("message_id1"))
			assert(t.fn2.params[1] == hash("message_id1"))
			assert(t.fn3.params[1] == nil)
			
			l2.trigger("message_id2")
			assert(t.fn1.calls == 2)
			assert(t.fn2.calls == 1)
			assert(t.fn3.calls == 1)
			assert(t.fn1.params[1] == hash("message_id2"))
			assert(t.fn2.params[1] == hash("message_id1"))
			assert(t.fn3.params[1] == hash("message_id2"))
		end)

		it("should be able add listener as urls and trigger them", function()
			local l = listener.create()
			l.add(msg.url("listener1"))
			l.add(msg.url("listener2"))
			
			l.trigger("message_id")
			assert(msg.post.calls == 2)
		end)

		it("should be able to pass a message to listeners when triggered", function()
			local t = {
				fn1 = function() end,
			}
			mock.mock(t)

			local l = listener.create()
			l.add(t.fn1)
			l.add(msg.url("listener1"))
			
			l.trigger("message_id", { foo = "bar" })
			assert(t.fn1.params[1] == hash("message_id"))
			assert(t.fn1.params[2].foo == "bar")
			assert(msg.post.params[1] == msg.url("listener1"))
			assert(msg.post.params[2] == hash("message_id"))
			assert(msg.post.params[3].foo == "bar")
		end)

		it("should be able to add listeners that react on specific message ids", function()
			local t = {
				fn1 = function() end,
				fn2 = function() end,
				fn3 = function() end,
			}
			mock.mock(t)

			local l = listener.create()
			l.add(t.fn1)
			l.add(t.fn2, "message_id1")
			l.add(t.fn2, "message_id2")
			l.add(t.fn3, "message_id2")
			l.add(msg.url("listener1"))
			l.add(msg.url("listener2"), "message_id1")
			l.add(msg.url("listener3"), "message_id2")
			
			l.trigger("message_id1")	-- fn1, fn2, listener1 and listener3
			assert(t.fn1.calls == 1)
			assert(t.fn2.calls == 1)
			assert(t.fn3.calls == 0)
			assert(msg.post.calls == 2)

			l.trigger("message_id2")	-- fn1, fn2, fn3, listener1, listner3
			assert(t.fn1.calls == 2)
			assert(t.fn2.calls == 2)
			assert(t.fn3.calls == 1)
			assert(msg.post.calls == 4)
		end)

		it("should ignore duplicate listeners", function()
			local t = {
				fn1 = function() end,
				fn2 = function() end,
				fn3 = function() end,
			}
			mock.mock(t)

			local l = listener.create()
			l.add(msg.url("listener1"))
			l.add(msg.url("listener1"))
			l.add(msg.url("listener2"))
			l.add(msg.url("listener3"), "message_id")
			l.add(msg.url("listener3"), "message_id")
			l.add(t.fn1)
			l.add(t.fn1)
			l.add(t.fn2)
			l.add(t.fn3, "message_id")
			l.add(t.fn3, "message_id")

			l.trigger("message_id")
			assert(msg.post.calls == 3)
			assert(t.fn1.calls == 1)
			assert(t.fn2.calls == 1)
			assert(t.fn3.calls == 1)
		end)

		it("should be able to remove listener previously added as functions", function()
			local t = {
				fn1 = function() end,
				fn2 = function() end,
				fn3 = function() end,
			}
			mock.mock(t)

			local l = listener.create()
			l.add(t.fn1)
			l.add(t.fn2)
			l.add(t.fn3, "message_id1")
			l.add(t.fn3, "message_id2")
			l.add(msg.url("listener1"))
			l.add(msg.url("listener2"))
			l.add(msg.url("listener3"), "message_id1")
			l.add(msg.url("listener3"), "message_id2")
			
			l.trigger("message_id1")
			assert(t.fn1.calls == 1)
			assert(t.fn2.calls == 1)
			assert(t.fn3.calls == 1)
			assert(msg.post.calls == 3)
			
			l.remove(t.fn2)
			l.remove(msg.url("listener2"))
			l.trigger("message_id1")
			assert(t.fn1.calls == 2)
			assert(t.fn2.calls == 1)
			assert(t.fn3.calls == 2)
			assert(msg.post.calls == 5)

			l.remove(t.fn3)
			l.remove(msg.url("listener3"))
			l.trigger("message_id1")
			assert(t.fn1.calls == 3)
			assert(t.fn2.calls == 1)
			assert(t.fn3.calls == 2)
			assert(msg.post.calls == 6)

			l.trigger("message_id2")
			assert(t.fn1.calls == 4)
			assert(t.fn2.calls == 1)
			assert(t.fn3.calls == 2)
			assert(msg.post.calls == 7)
			
			-- remove the rest of the listeners and trigger both message ids
			-- no new calls should be made
			l.remove(t.fn1)
			l.remove(msg.url("listener1"))
			l.trigger("message_id1")
			l.trigger("message_id2")
			assert(t.fn1.calls == 4)
			assert(t.fn2.calls == 1)
			assert(t.fn3.calls == 2)
			assert(msg.post.calls == 7)
		end)
		
	end)
end