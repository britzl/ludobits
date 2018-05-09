local mock = require "deftest.mock.mock"
local mock_fs = require "deftest.mock.fs"
local unload = require "deftest.util.unload"

return function()
	local savefile
	
	describe("savefile", function()
		before(function()
			unload.unload("ludobits.")
			mock_fs.mock()
			savefile = require "ludobits.m.io.savefile"
		end)

		after(function()
			mock_fs.unmock()
		end)

		it("should be able to save and load files", function()
			local file1 = savefile.open("foobar1")
			local file2 = savefile.open("foobar2")
			local t1 = file1.load()
			local t2 = file2.load()
			assert(not t1)
			assert(not t2)
			file1.save("foobar")

			local t1 = file1.load()
			local t2 = file2.load()
			assert(t1 == "foobar")
			assert(not t2)
		end)
	end)
end