local mock = require "deftest.mock"

return function()
	local input = require "in.state"
	
	describe("input", function()
		before(function()
			mock.mock(msg)
			msg.post.replace(function() end)
		end)

		after(function()
			mock.unmock(msg)
		end)

		it("should post a message to acquire input focus", function()
			input.acquire()
			assert(msg.post.calls == 1)
			assert(msg.post.params[1] == ".")
			assert(msg.post.params[2] == "acquire_input_focus")
		end)

		it("should post a message to release input focus", function()
			input.release()
			assert(msg.post.calls == 1)
			assert(msg.post.params[1] == ".")
			assert(msg.post.params[2] == "release_input_focus")
		end)

		it("should keep track of pressed and released state of action ids", function()
			local action_id1 = hash("action1")
			local action_id2 = hash("action2")
			local pressed = { pressed = true }
			local released = { released = true }
			
			assert(not input.is_pressed(action_id1))
			assert(not input.is_pressed(action_id2))
			
			input.on_input(action_id1, pressed)
			assert(input.is_pressed(action_id1))
			assert(not input.is_pressed(action_id2))

			input.on_input(action_id2, pressed)
			assert(input.is_pressed(action_id1))
			assert(input.is_pressed(action_id2))

			input.on_input(action_id1, released)
			assert(not input.is_pressed(action_id1))
			assert(input.is_pressed(action_id2))

			input.on_input(action_id2, released)
			assert(not input.is_pressed(action_id1))
			assert(not input.is_pressed(action_id2))
		end)

		it("should only care about action.pressed and action.released", function()
			local action_id = hash("action")
			local pressed = { pressed = true }
			local released = { released = true }
			local repeated = { repeated = true }

			input.on_input(action_id, repeated)
			assert(not input.is_pressed(action_id))
			
			input.on_input(action_id, pressed)
			assert(input.is_pressed(action_id))

			input.on_input(action_id, repeated)
			assert(input.is_pressed(action_id))

			input.on_input(action_id, released)
			assert(not input.is_pressed(action_id))
		end)

		it("should handle both string and hash as action_id", function()
			local action_id_hash = hash("action1")
			local action_id_string = hash("action1")
			local pressed = { pressed = true }
			local released = { released = true }

			assert(not input.is_pressed(action_id_string))
			assert(not input.is_pressed(action_id_hash))

			input.on_input(action_id_string, pressed)
			assert(input.is_pressed(action_id_string))
			assert(input.is_pressed(action_id_hash))

			input.on_input(action_id_string, released)
			assert(not input.is_pressed(action_id_string))
			assert(not input.is_pressed(action_id_hash))

			input.on_input(action_id_hash, pressed)
			assert(input.is_pressed(action_id_string))
			assert(input.is_pressed(action_id_hash))
		end)


		it("should be able to create multiple instances", function()
			local action_id1 = hash("action1")
			local action_id2 = hash("action2")
			local pressed = { pressed = true }
			local released = { released = true }

			local input1 = input.create()
			local input2 = input.create()
			
			assert(not input1.is_pressed(action_id1))
			assert(not input1.is_pressed(action_id2))
			assert(not input2.is_pressed(action_id1))
			assert(not input2.is_pressed(action_id2))

			input1.on_input(action_id1, pressed)
			assert(input1.is_pressed(action_id1))
			assert(not input2.is_pressed(action_id1))

			input2.on_input(action_id2, pressed)
			assert(input1.is_pressed(action_id1))
			assert(not input2.is_pressed(action_id1))
			assert(not input1.is_pressed(action_id2))
			assert(input2.is_pressed(action_id2))
			
			input1.on_input(action_id1, released)
			assert(not input1.is_pressed(action_id1))
			input2.on_input(action_id2, released)
			assert(not input2.is_pressed(action_id2))
		end)
	end)
end