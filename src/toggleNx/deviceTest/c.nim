import logging
let consoleLogger = newConsoleLogger()
let fileLogger = newFileLogger()

addHandler(consoleLogger)
addHandler(fileLogger)

proc testDevice*(filename: cstring, content: cstring): void {.exportc, raises: [].} =
  var s: string = "Nim chnaged!"
  try:
    debug "initial string: ", s
    debug "params ", $filename, ", ", $content
    when defined(posix) and not defined(nimscript):
      debug "posix defined!"
    when defined(nintendoswitch):
      debug "nintendoswitch defined!"
    debug "try"
    var f = open($filename, fmWrite)
    debug "opened"
    f.write(content)
    debug "writen"
    f.close()
    debug "closed"


    f = open($filename)
    debug "opened again"
    debug "read: ", f.readAll()
    f.close()
    debug "closed"
    # f.write(content)
    s = "OK"
    debug "s = ok"
  except Exception as e:
    echo "exception"
    s = "Cannot write file: " & $e.name & " " & e.msg
  echo "final"
  echo s
