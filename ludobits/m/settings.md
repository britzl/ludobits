# Settings
Use the Settings module to save user settings to disk.

# Usage

	local settings = require "ludobits.m.settings"

	settings.volume = 0.7
	settings.language = "en"
	settings.username = "Johnny Defold"

	settings.save()

# Limitations
The Settings module will serialize the settings using the Savetable module and is thus limited to the data types supported by that module.
