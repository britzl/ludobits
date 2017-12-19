local mock = require "deftest.mock"
local mock_fs = require "deftest.mock.fs"

return function()
	local savetable = require "ludobits.m.savetable"
	
	describe("savetable", function()
		before(function()
			mock_fs.mock()
		end)

		after(function()
			mock_fs.unmock()
		end)

		it("should be able to save and load tables", function()
			local file1 = savetable.open("foobar1")
			local file2 = savetable.open("foobar2")
			local t1, err = file1.load()
			local t2 = file2.load()
			assert(not t1)
			assert(not t2)
			file1.save({ foo = "bar" })

			local t1 = file1.load()
			local t2 = file2.load()
			assert(t1.foo == "bar")
			assert(not t2)
		end)
	end)
end