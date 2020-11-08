# Logger
The Logger module provides a simple logging framework to log application events of different severities to standard out. The module supports simple filtering based on severity.

# Usage

```lua
	local logger = require "ludobits.m.logger"

	local log = logger.create("foo")

	log.d("This will be logged with level DEBUG")
	log.debug("And this too")
	log("And this too")
	log.i("This will be logged with level INFO")
	log.info("And this too")
	log.w("This will be logged with level WARN")
	log.warn("And this too")
	log.e("This will be logged with level ERROR")
	log.error("And this too")
	log.f("This will be logged with level FATAL")
	log.fatal("And this too")

	-- only log WARN and above
	logger.level(logger.WARN)

	log.d("This will not be logged since the minimum log level is set to WARN")
```
