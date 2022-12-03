import std/streams
import std/json
import std/tables

type
  ResultKind* = enum
    rkSuccess
    rkError
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

  Section* = ref object
    name: string
    separatedAbove: bool
    separatedBelow: bool
    entities: seq[Entity]

  Settings* = ref object
    name*: string
    sections: seq[Section]
    path: string
    entities: Table[string, Entity]

  SettingsResult* = ref SettingsResultObj
  SettingsResultObj = object
    case kind*: ResultKind

    of rkSuccess:
      settings*: Settings

    of rkError:
      error*: string

  EntityResult* = ref EntityResultObj
  EntityResultObj = object
    case kind*: ResultKind

    of rkSuccess:
      entity*: Entity

    of rkError:
      error*: string

func loadFromJson(jsonData: JsonNode): Settings =
  ## Deserialize JSON into Settings

  let settingsName = jsonData["name"].getStr

  var sections: seq[Section] = @[]
  var entities = Table[string, Entity]()

  for sectionData in jsonData["sections"]:
    var sEntities: seq[Entity] = @[]

    for entityData in sectionData["entities"]:
      var entity = to(entityData, Entity)
      if entities.hasKey(entity.name):
        raise newException(ValueError, "duplicate names in entities detected: " & entity.name)
      entities[entity.name] = entity
      sEntities.add(entity)

    var section = Section(name: sectionData["name"].getStr, entities: sEntities)
    sections.add(section)

  Settings(name: settingsName, sections: sections, entities: entities)

proc saveSettings*(settings: Settings): SettingsResult {.raises: [].} =
  var error: string = ""
  try:
    let f = open(settings.path, fmWrite)
    defer: f.close()
    f.write( %* settings)
    result = SettingsResult(kind: rkSuccess, settings: settings)
  except Exception as e:
    error = "couldn't save settings to file: " & e.msg

  if error != "":
    result = SettingsResult(kind: rkError, error: error)

proc loadSettings*(path: string): SettingsResult {.raises: [].} =
  var error: string = ""
  try:
    let f = openFileStream(path)
    defer: f.close()
    let jData = parseJson(f)
    let s = loadFromJson(jData)
    s.path = path
    result = SettingsResult(kind: rkSuccess, settings: s)

  except Exception as e:
    error = """Couldn't open file """" & path & """": """" & e.msg & """"."""

  if error != "":
    result = SettingsResult(kind: rkError, error: error)

proc set*[T](
  settings: Settings,
  entity: string,
  value: T
): EntityResult {.raises: [].} =
  ## Sets the field on the settings object (in-place) and saves settings to drive,
  ## gets the resulting value back
  template typeErrorMsg(type_repr, field_type_repr,
      entity_name: string): string =
    "supplied value of type " & type_repr & " cannot be assigned to " &
        field_type_repr & " field " & entity_name

  var error = ""
  var result_entity: Entity
  try:
    result_entity = settings.entities[entity]
  except KeyError as e:
    error = e.msg

  case result_entity.kind

  of ekSwitch:
    error = typeErrorMsg(T.repr, "ekSwitch", entity)
    when T is bool:
      result_entity.switchVal = value
      error = ""

  of ekChar:
    error = typeErrorMsg(T.repr, "ekChar", entity)
    when T is string:
      let l = value.len()
      if result_entity.minLength <= l.uint and l.uint <=
          result_entity.maxLength:
        result_entity.charVal = value
        error = ""
      else:
        error = "supplied value for " & entity & " has invalid length: " & value

  of ekChoice:
    error = typeErrorMsg(T.repr, "ekChoice", entity)
    when T is uint:
      if result_entity.choices.low.uint <= value and value <=
          result_entity.choices.high.uint:
        result_entity.choiceVal = value
        error = ""
      else:
        error = "no such choice in " & entity

  of ekSlider:
    error = typeErrorMsg(T.repr, "ekSlider", entity)
    when T is uint:
      if result_entity.minValue <= value and value <= result_entity.maxValue:
        result_entity.sliderVal = value
        error = ""
      else:
        error = "supplied value is not in the bounds of " & entity


  # TODO: store at FS
  if error != "":
    result = EntityResult(kind: rkError, error: error)
  else:
    let sr = settings.saveSettings()
    if sr.kind == rkError:
      result = EntityResult(kind: rkError, error: sr.error)
    else:
      result = EntityResult(kind: rkSuccess, entity: result_entity)

proc get*(
  settings: Settings,
  entity: string
): EntityResult {.raises: [], exportc.} =
  ## Gets the value from settings object
  try:
    result = EntityResult(kind: rkSuccess, entity: settings.entities[entity])
  except KeyError as e:
    result = EntityResult(kind: rkError, error: e.msg)

when isMainModule:
  import std/unittest
  import strutils
  from std/os import getTempDir, `/`

  proc initDb(db_json: JsonNode): string =
    let td = getTempDir()
    let dbPath = td/"db.json"
    let f = open(dbPath, fmWrite)
    f.write(db_json.pretty)
    f.close()
    dbPath

  suite "db tests":
    test "test cannot load with same entities":
      let db_json = %*{
          "name": "Test",
          "sections": [
            {
                  "name": "Test Section",
                  "separatedAbove": false,
                  "separatedBelow": false,
                  "entities": [
                      {
                          "name": "Enable NiceSetting",
                          "helptext": "Enable this to configure app perfectly :)",
                          "separatedAbove": false,
                          "separatedBelow": false,
                          "kind": "ekSwitch",
                          "switchVal": false
                      }
                  ]
            },
            {
                  "name": "Test Section",
                  "separatedAbove": false,
                  "separatedBelow": false,
                  "entities": [
                      {
                          "name": "Enable NiceSetting",
                          "helptext": "Enable this to configure app perfectly :)",
                          "separatedAbove": false,
                          "separatedBelow": false,
                          "kind": "ekSwitch",
                          "switchVal": false
                      }
                  ]
            }
          ]
      }
      let dbPath = initDb(db_json)

      let sr = loadSettings(dbPath)
      check(sr.kind == rkError)
      check(sr.error.contains("duplicate names in entities detected"))
    test "test load basic settings from file":
      let db_json = %*{
          "name": "Test",
          "sections": []
      }
      let dbPath = initDb(db_json)

      var s = loadSettings(dbPath)
      case s.kind
      of rkError:
        raise newException(Exception, s.error)
      of rkSuccess:
        check(s.settings.name == "Test")

    test "test load settings, modify, save":
      var
        er: EntityResult
        sr: SettingsResult
        name: string
      let db_json = %*{
          "name": "Test",
          "sections": [
              {
                  "name": "Test Section",
                  "separatedAbove": false,
                  "separatedBelow": false,
                  "entities": [
                      {
                          "name": "Enable NiceSetting",
                          "helptext": "Enable this to configure app perfectly :)",
                          "separatedAbove": false,
                          "separatedBelow": false,
                          "kind": "ekSwitch",
                          "switchVal": false
                      },
                      {
                          "name": "Enable NiceSetting 2",
                          "helptext": "Enable this to configure app perfectly :)",
                          "separatedAbove": true,
                          "separatedBelow": false,
                          "kind": "ekChar",
                          "charVal": "someDefaults",
                          "minLength": 2,
                          "maxLength": 32,
                      },
                      {
                          "name": "Enable NiceSetting 3",
                          "helptext": "Enable this to configure app perfectly :)",
                          "separatedAbove": true,
                          "separatedBelow": true,
                          "kind": "ekChoice",
                          "choiceVal": 0,
                          "choices": ["Choice #0", "Another choice"]
                      },
                      {
                          "name": "Enable NiceSetting 4",
                          "helptext": "Enable this to configure app perfectly :)",
                          "separatedAbove": false,
                          "separatedBelow": true,
                          "kind": "ekSlider",
                          "sliderVal": 3,
                          "minValue": 2,
                          "maxValue": 5
                      }
                  ]
              }
          ]
      }
      let dbPath = db_json.initDb()
      sr = loadSettings(dbPath)
      case sr.kind
      of rkError:
        raise newException(Exception, sr.error)
      of rkSuccess:
        check(sr.settings.name == "Test")

        # ekSwitch
        name = "Enable NiceSetting"
        er = sr.settings.get(name)
        check(er.kind == rkSuccess)
        check(er.entity.kind == ekSwitch)
        check(er.entity.switchVal == false)

        er = sr.settings.set(name, true)
        check(er.kind == rkSuccess)
        check(er.entity.kind == ekSwitch)
        check(er.entity.switchVal == true)

        sr = loadSettings(dbPath)
        check(sr.kind == rkSuccess)

        er = sr.settings.get(name)
        check(er.kind == rkSuccess)
        check(er.entity.kind == ekSwitch)
        check(er.entity.switchVal == true)

        # ekChar
        name = "Enable NiceSetting 2"
        er = sr.settings.get(name)
        check(er.kind == rkSuccess)
        check(er.entity.kind == ekChar)
        check(er.entity.charVal == "someDefaults")

        er = sr.settings.set(name, "someChangedDefaults")
        check(er.kind == rkSuccess)
        check(er.entity.kind == ekChar)
        check(er.entity.charVal == "someChangedDefaults")

        sr = loadSettings(dbPath)
        check(sr.kind == rkSuccess)

        er = sr.settings.get(name)
        check(er.kind == rkSuccess)
        check(er.entity.kind == ekChar)
        check(er.entity.charVal == "someChangedDefaults")

        er = sr.settings.set(name, "n")
        check(er.kind == rkError)
        check(er.error.contains("has invalid length:"))
        er = sr.settings.set(name, "too Long String for that field, oh my, how long it is")
        check(er.kind == rkError)
        check(er.error.contains("has invalid length:"))

        # ekChoice
        name = "Enable NiceSetting 3"
        er = sr.settings.get(name)
        check(er.kind == rkSuccess)
        check(er.entity.kind == ekChoice)
        check(er.entity.choiceVal == 0)

        er = sr.settings.set(name, 1.uint)
        check(er.kind == rkSuccess)
        check(er.entity.kind == ekChoice)
        check(er.entity.choiceVal == 1)

        sr = loadSettings(dbPath)
        check(sr.kind == rkSuccess)

        er = sr.settings.get(name)
        check(er.kind == rkSuccess)
        check(er.entity.kind == ekChoice)
        check(er.entity.choiceVal == 1)

        er = sr.settings.set(name, 42.uint)
        check(er.kind == rkError)
        check(er.error.contains("no such choice in"))

        # ekSlider
        name = "Enable NiceSetting 4"
        er = sr.settings.get(name)
        check(er.kind == rkSuccess)
        check(er.entity.kind == ekSlider)
        check(er.entity.sliderVal == 3)

        er = sr.settings.set(name, 2.uint)
        check(er.kind == rkSuccess)
        check(er.entity.kind == ekSlider)
        check(er.entity.sliderVal == 2)

        sr = loadSettings(dbPath)
        check(sr.kind == rkSuccess)

        er = sr.settings.get(name)
        check(er.kind == rkSuccess)
        check(er.entity.kind == ekSlider)
        check(er.entity.sliderVal == 2)

        er = sr.settings.set(name, 1.uint)
        check(er.kind == rkError)
        check(er.error.contains("supplied value is not in the bounds of"))
        er = sr.settings.set(name, 7.uint)
        check(er.kind == rkError)
        check(er.error.contains("supplied value is not in the bounds of"))
