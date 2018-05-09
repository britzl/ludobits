local mock = require "deftest.mock.mock"
local mock_fs = require "deftest.mock.fs"
local unload = require "deftest.util.unload"

return function()
	local file
	
	describe("file", function()
		before(function()
			unload.unload("ludobits.")
			mock_fs.mock()
			file = require "ludobits.m.io.file"
		end)

		after(function()
			mock_fs.unmock()
		end)

		it("should be able to fix filenames with illegal characters", function()
			assert(file.fix("foobar") == "foobar")
			assert(file.fix("foo.bar") == "foo.bar")
			assert(file.fix("foo_bar") == "foo_bar")
			assert(file.fix("foo bar") == "foo+bar")
			assert(file.fix("O/>") == "O%2F%3E")
			assert(file.fix("foo\nbar") == "foo%0Abar")
		end)
	end)
end