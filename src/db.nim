import std/strformat
import std/json

type
  ResultKind = enum
    rkSuccess
    rkError
  EntityKind = enum
    dkChar,
    dkSwitch,
    dkSlider,
    dkChoice

  Entity = ref EntityObj
  EntityObj = object
    name: cstring
    helptext: cstring
    separatedAbove: cushort
    separatedBelow: cushort

    case kind: EntityKind

    of dkChar:
      charVal: cstring
      minLength, maxLength: cushort

    of dkSwitch:
      boolVal: cushort

    of dkSlider:
      intVal: cushort
      minValue, maxValue: cushort

    of dkChoice:
      uintVal: cuint
      choices: seq[cstring]

  Section = ref object 
    name: cstring
    separatedAbove: cushort
    separatedBelow: cushort
    entities: seq[Entity]

  Settings = ref object
    name: cstring
    sections: seq[Section]
    path: cstring

  SettingsResult = ref SettingsResultObj
  SettingsResultObj = object
    case kind: ResultKind

    of rkSuccess:
      settings: Settings

    of rkError:
      error: cstring

  EntityResult = ref EntityResultObj
  EntityResultObj = object
    case kind: ResultKind

    of rkSuccess:
      entity: Entity

    of rkError:
      error: cstring


func serialize(settings: Settings): cstring = "" # TODO: serialize into JSON
func deserialize(settings: Settings, settingsJson: cstring): void = 
  settings.name="test"
  settings.sections = @[]
  settings.path = "/config/test_settings.json"
  # TODO: build Settings from JSON

proc loadSettings(path: cstring): SettingsResult = SettingsResult(kind: rkError, error: "Not Implemented")

proc set*[T](
  settings: Settings,
  sectionName, entity: cstring,
  value: T
): EntityResult {.exportc.} =
  ## Sets the field on the settings object (in-place) and saves settings to drive,
  ## gets the resulting value back
  EntityResult(kind: rkError, error: "Not implemented yet!")

proc get*[T](
  settings: Settings,
  sectionName, entity: cstring
): EntityResult {.exportc.} =
  ## Gets the value from settings object
  EntityResult(kind: rkError, error: "Not implemented yet!")

if isMainModule:
  var s = Settings()
  
  deserialize(s, "")

  echo s.name
