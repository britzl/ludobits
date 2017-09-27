local mock = require "deftest.mock"
local mock_fs = require "deftest.mock.fs"

return function()
	local settings = require "ludobits.m.settings"
	
	describe("settings", function()
		before(function()
			mock_fs.mock()
		end)

		after(function()
			mock_fs.unmock()
		end)

		it("should start empty", function()
			assert(settings.foo == nil)
		end)

		it("should be possible to set and get values", function()
			assert(settings.foo == nil)
			assert(settings.boo == nil)
			settings.foo = "bar"
			settings.boo = "car"
			assert(settings.foo == "bar")
			assert(settings.boo == "car")
		end)

		it("should be possible to set, save and later load values", function()
			settings.foo = "bar"
			settings.boo = "car"
			settings.save()
			
			-- unload and require again, make sure we get a new table
			package.loaded["ludobits.m.settings"] = nil
			local newsettings = require("ludobits.m.settings")
			assert(settings ~= newsettings)
			
			assert(newsettings.foo == "bar")
			assert(newsettings.boo == "car")
		end)
	end)
end