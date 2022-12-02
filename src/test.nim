type 
  EntityKind* = enum
    ekChar,
    ekSwitch,
    ekSlider,
    ekChoice

  Entity* = ref EntityObj
  EntityObj = object
    name*: string
    helptext*: string
    separatedAbove*: bool
    separatedBelow*: bool

    case kind*: EntityKind

    of ekChar:
      charVal*: string
      minLength*, maxLength*: uint

    of ekSwitch:
      switchVal*: bool

    of ekSlider:
      sliderVal*: uint
      minValue*, maxValue*: uint

    of ekChoice:
      choiceVal*: uint
      choices*: seq[string]

proc set(e: Entity, val: bool) = 
    e.switchVal = val

if isMainModule:
    var x = Entity(name: "test", kind: ekSwitch, 
        helptext: "",
        separatedAbove: false,
        separatedBelow: false,
        switchVal: false
    )
    x.set(true)
    echo x.switchVal
    