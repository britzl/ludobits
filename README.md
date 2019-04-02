# Ludobits
Utilities for game development using the [Defold](http://www.defold.com) engine.

[![Travis-CI](https://travis-ci.org/britzl/ludobits.svg?branch=master)](https://travis-ci.org/britzl/ludobits)

## Modules

### ludobits.m.io.file
File name and path utilities

### ludobits.m.io.savefile
Read/write files

### ludobits.m.io.savetable
Read/write Lua tables

### ludobits.m.app
Wrap engine callbacks from iac, iap, push and window. Refer to [app.md](ludobits/m/app.md) for usage details.

### ludobits.m.bezier
Create bezier curves

### ludobits.m.broadcast
Broadcast Defold messages (using msg.post) and set up optional function callbacks when messages are received. Refer to [broadcast.md](ludobits/m/broadcast.md) for usage details.

### ludobits.m.flow
Simplifies asynchronous flows of execution where your code needs to wait for one asynchronous operation to finish before tarting with the next one.

### ludobits.m.json
JSON encode (using rxi.json)

### ludobits.m.listener
Listener implementation where listeners are added as either urls or functions and notified when any or specific messages are received. Refer to [listener.md](ludobits/m/listener.md) for usage details.

### ludobits.m.logger
The Logger module provides a simple logging framework to log application events of different severities to standard out. The module supports simple filtering based on severity. Refer to [logger.md](ludobits/m/logger.md) for usage details.

### ludobits.m.settings
Store user settings to disk. Refer to [settings.md](ludobits/m/settings.md) for usage details.

### ludobits.m.signal
Signal system where named signals can be created, listened to and triggered. Inspired by as3-signals. Refer to [signal.md](ludobits/m/signal.md) for usage details.
