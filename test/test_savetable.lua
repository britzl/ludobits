local mock = require "deftest.mock.mock"
local mock_fs = require "deftest.mock.fs"
local unload = require "deftest.util.unload"

return function()
	local savetable
	
	describe("savetable", function()
		before(function()
			unload.unload("ludobits.")
			mock_fs.mock()
			savetable = require "ludobits.m.io.savetable"
		end)

		after(function()
			mock_fs.unmock()
		end)

		it("should be able to load and save tables", function()
			local file1 = savetable.load("foobar1", savetable.FORMAT_IO)
			local file2 = savetable.load("foobar2", savetable.FORMAT_SYS)
			file1.boba = "fett"
			file2.luke = "skywalker"
			savetable.save(file1)
			savetable.save(file2)

			local file1 = savetable.load("foobar1", savetable.FORMAT_IO)
			local file2 = savetable.load("foobar2", savetable.FORMAT_SYS)
			assert(file1.boba == "fett")
			assert(file2.luke == "skywalker")

			local file3 = {}
			file3.darth = "vader"
			savetable.save(file3, "foobar3", savetable.FORMAT_SYS)

			local file3 = savetable.load("foobar3", savetable.FORMAT_SYS)
			assert(file3.darth == "vader")
		end)

		it("should be able to save and load tables", function()
			local file3 = { darth = "vader" }
			local file4 = { han  ="solo" }
			savetable.save(file3, "foobar3", savetable.FORMAT_IO)
			savetable.save(file4, "foobar4", savetable.FORMAT_SYS)
						
			local file3 = savetable.load("foobar3", savetable.FORMAT_IO)
			local file4 = savetable.load("foobar4", savetable.FORMAT_SYS)
			assert(file3.darth == "vader")
			assert(file4.han == "solo")
		end)
	end)
end