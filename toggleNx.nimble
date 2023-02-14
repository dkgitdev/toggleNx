# Package

version       = "0.1.0"
author        = "Dmitry Arkhipenko"
description   = "A pluggable settings library for Nintendo Switch"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.6.6"
requires "switch_build >= 0.1.4"

task test, "Runs the test suite":
  exec "rm -rf build/"
  exec "nim c src/toggleNx/db/db.nim"
  exec "./build/db"
  exec "nim c src/toggleNx/db/c.nim"
  exec "./build/c"
  exec "nimble build_pc"
  exec "nimble build_nx"

task build_pc, "Build PC C library":
  exec "rm -rf build/"
  exec "nim c --noLinking:on --noMain:on src/toggleNx.nim"

task build_nx, "Build NX C library":
  exec "rm -rf build/"
  exec "switch_build -S src/toggleNx.nim"

task build_device_test, "Build NX C library":
  exec "rm -rf build/"
  exec "switch_build -S src/toggleNx/deviceTest/c.nim"
  cd("libs/nimNxStatic")
  exec "make clean && make"
  exec "mv *.elf ../../build"
  exec "mv *.nacp ../../build"
  exec "mv *.nro ../../build"
  exec "rm -rf build"
