# Signal
Module to create a signal system where named signals can be created, listened to and triggered.

## Usage

	-- example_module.lua
	local signal = require "ludobits.m.signal"

	local M = {}

	M.LOGIN_SUCCESS_SIGNAL = signal.create("login_success")
	M.LOGOUT_SIGNAL = signal.create("logout")

	function M.login()
		.. perform async login and then
		M.LOGIN_SUCCESS_SIGNAL.trigger({ user = "Foobar" })
	end

	function M.logout()
		M.LOGOUT_SIGNAL.trigger()
	end

	return M


	--some.script
	local example_module = require "example_module"

	function init(self)
		example_module.LOGIN_SUCCESS_SIGNAL.add(function(message)
			print("login success", message.user)
		end)
		example_module.LOGOUT_SIGNAL.add()
	end

	function on_message(self, message_id, message, sender)
		if message_id == hash(example_module.LOGOUT_SIGNAL.id) then
			print("User logged out")
		end
	end
