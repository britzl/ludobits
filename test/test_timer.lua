local mock = require "deftest.mock"

return function()
	local timer = require "ludobits.m.timer"

	local o = {
		cb = function() end
	}
	
	describe("timer", function()
		before(function()
			mock.mock(o)
		end)

		after(function()
			mock.unmock(o)
		end)

		it("should call a function after a certain time has elapsed", function()
			local t = timer.once(3, o.cb)
			t.update(2)
			assert(o.cb.calls == 0)
			t.update(1)
			assert(o.cb.calls == 1)
			t.update(3)
			assert(o.cb.calls == 1)
		end)
		
		it("should be possible to reset a timer", function()
			local t = timer.once(3, o.cb)
			t.update(3)
			assert(o.cb.calls == 1)
			t.reset()
			t.update(3)
			assert(o.cb.calls == 2)
		end)
		
		it("should be possible to directly manipulate timer delay", function()
			local t = timer.once(3, o.cb)
			assert(t.seconds)
			t.seconds = 5
			t.update(3)
			assert(o.cb.calls == 0)
			t.update(2)
			assert(o.cb.calls == 1)
		end)

		it("should be possible to repeat a callback with a regular interval", function()
			local t = timer.every(3, o.cb)
			t.update(3)
			assert(o.cb.calls == 1)
			t.update(3)
			assert(o.cb.calls == 2)
			t.update(3)
			assert(o.cb.calls == 3)
		end)
	end)
end