local mock = require "deftest.mock.mock"
local mock_fs = require "deftest.mock.fs"
local unload = require "deftest.util.unload"

return function()
	local settings
	
	describe("settings", function()
		before(function()
			unload.unload("ludobits.")
			mock_fs.mock()
			settings = require "ludobits.m.settings"
		end)

		after(function()
			mock_fs.unmock()
		end)

		it("should start empty", function()
			assert(settings.is_empty())
		end)

		it("should be possible to set and get values", function()
			assert(settings.foo == nil)
			assert(settings.boo == nil)
			settings.foo = "bar"
			settings.boo = "car"
			assert(settings.foo == "bar")
			assert(settings.boo == "car")
			assert(not settings.is_empty())
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
		
		it("should be possible to load and save to multiple files", function()
			-- set and save to default file
			assert(settings.is_empty())
			settings.foo = "foodefault"
			settings.save()

			-- set and save to file1
			settings.load("file1")
			assert(settings.filename() == "file1")
			assert(settings.is_empty())
			settings.foo = "foofile1"
			settings.save()

			-- load default file again and save it to a file2
			settings.load()
			assert(settings.foo == "foodefault")
			settings.foo = "foofile2"
			settings.save("file2")
			assert(settings.filename() == "file2")			

			-- load file1 and make sure it is unchanged
			settings.load("file1")
			assert(settings.filename() == "file1")
			assert(settings.foo == "foofile1")
		end)
	end)
end