# This is just an example to get you started. A typical library package
# exports the main API in this file. Note that you cannot rename this file
# but you can remove it if you wish.

import db/db
import db/c

proc testFileWrite*(filename: cstring, content: cstring): void {.exportc, raises: [].} = 
  var s: string = "Nim chnaged!"
  echo s
  echo "args: " & $filename & ", " & $content
  when defined(posix) and not defined(nimscript):
    echo "posix defined!"
  when defined(nintendoswitch):
    echo "nintendoswitch defined!"
  try:
    echo "try"
    var f = open($filename, fmWrite)
    echo "opened"
    f.write(content)
    echo "writen"
    f.close()
    echo "closed"


    f = open($filename)
    echo "opened again"
    echo "read: " & f.readAll()
    f.close()
    echo "closed"
    # f.write(content)
    s = "OK"
    echo "s = ok"
  except Exception as e:
    echo "exception"
    s = "Cannot write file: " & $e.name & " " & e.msg
  echo "final"
  echo s
