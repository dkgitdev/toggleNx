# Package

version       = "0.1.0"
author        = "Dmitry Arkhipenko"
description   = "A pluggable settings library for Nintendo Switch"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.6.6"
requires "switch_build >= 0.1.4"
requires "chronicles ^= 0.10.3"

task test, "Runs the test suite":
  exec "nim c -r src/toggleNx/db/db.nim"
  exec "rm src/toggleNx/db/db"
  exec "nim c -r src/toggleNx/db/c.nim"
  exec "rm src/toggleNx/db/c"
