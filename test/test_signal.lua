local mock = require "deftest.mock.mock"
local unload = require "deftest.util.unload"
local signal = require "ludobits.m.signal"

return function()

	describe("signal", function()
		before(function()
			unload.unload("ludobits.")
		end)

		after(function()
		end)

		it("should have an id", function()
			local foo = signal.create("FOO")
			local bar = signal.create("BAR")
			assert(foo.id == hash("FOO"))
			assert(bar.id == hash("BAR"))
		end)
		
		it("should invoke added callbacks when triggered", function()
			local foo = signal.create("FOO")
			local bar = signal.create("BAR")

			local r = ""
			foo.add(function() r = r .. "foo" end)
			foo.add(function() r = r .. "foo" end)
			bar.add(function() r = r .. "bar" end)
			foo.trigger()
			assert(r == "foofoo")
			bar.trigger()
			assert(r == "foofoobar")
		end)

		it("should not invoke removed callbacks when triggered", function()
			local foo = signal.create("FOO")

			local r = ""
			local function a() r = r .. "a" end
			local function b() r = r .. "b" end
			foo.add(a)
			foo.add(b)
			foo.trigger()
			assert(r == "ab" or r == "ba")
			foo.remove(a)
			foo.trigger()
			assert(r == "abb" or r == "bab")
		end)

		it("should pass the message to callbacks when triggered", function()
			local foo = signal.create("FOO")
			local bar = signal.create("BAR")

			local r = ""
			foo.add(function(message) r = r .. message end)
			foo.add(function(message) r = r .. message end)
			bar.add(function(message) r = r .. message end)
			foo.trigger("a")
			assert(r == "aa")
			foo.trigger("b")
			assert(r == "aabb")
			bar.trigger("c")
			assert(r == "aabbc")
		end)
	end)
end