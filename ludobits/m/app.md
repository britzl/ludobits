# App
Module to simplify the use of several of the engine listeners. The module allows the user to define multiple listeners for the iac, iap, push and window listeners.

## Usage

```lua
	local app = require "ludobits.app"

	local function iac_listener1(self, playload, type)
		print("This function will receive callbacks")
	end

	local function iac_listener2(self, playload, type)
		print("And this function too")
	end

	app.iac.add_listener(iac_listener1)
	app.iac.add_listener(iac_listener2)
```