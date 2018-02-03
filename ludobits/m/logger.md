# Logger
The Logger module provides a simple logging framework to log application events of different severities to standard out. The module supports simple filtering based on severity.

# Usage

	local logger = require "ludobits.m.logger"

	local log1 = logger.create("foo")

	log1.d("This will be logged with level DEBUG")
	log1.debug("And this too")
	log1("And this too")
	log1.i("This will be logged with level INFO")
	log1.info("And this too")
	log1.w("This will be logged with level WARN")
	log1.warn("And this too")
	log1.e("This will be logged with level ERROR")
	log1.error("And this too")
	log1.f("This will be logged with level FATAL")
	log1.fatal("And this too")

	-- only log WARN and above
	log1.level(logger.WARN)

	local log2 = logger.create("bar")
	log2.d("This will still be logged since the level was set on another instance")
