# import chronicles

# proc testFileWrite*(filename: cstring, content: cstring): void {.exportc, raises: [].} = 
#   var s: string = "Nim chnaged!"
#   try:
#     debug "initial string", someString = s
#     debug "params", filename = $filename, content = $content
#     when defined(posix) and not defined(nimscript):
#       debug "posix defined!"
#     when defined(nintendoswitch):
#       debug "nintendoswitch defined!"
#     debug "try"
#     var f = open($filename, fmWrite)
#     debug "opened"
#     f.write(content)
#     debug "writen"
#     f.close()
#     debug "closed"


#     f = open($filename)
#     debug "opened again"
#     debug "read: ", contents = f.readAll()
#     f.close()
#     debug "closed"
#     # f.write(content)
#     s = "OK"
#     debug "s = ok"
#   except Exception as e:
#     echo "exception"
#     s = "Cannot write file: " & $e.name & " " & e.msg
#   echo "final"
#   echo s
