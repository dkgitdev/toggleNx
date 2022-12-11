import os
import std/logging

createDir("logs/")
let fileHandler = newRollingFileLogger("logs/toggleNx.log", levelThreshold=lvlAll)
let consoleHandler = newConsoleLogger(levelThreshold=lvlAll)
addHandler(fileHandler)
addHandler(consoleHandler)

export logging
