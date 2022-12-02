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
    f.write(%* settings)
    result = SettingsResult(kind: rkSuccess, settings: settings)
  except Exception as e:
    error = "couldn't save settings to file: " & e.msg
  
  if error != "":
    result = SettingsResult(kind: rkError, error: error)

proc loadSettings*(path: string): SettingsResult {.raises:[].} = 
  var error: string = ""
  try:
    let f = openFileStream(path)
    defer: f.close()
    let jData = parseJson(f)
    let s = loadFromJson(jData)
    s.path = path
    result = SettingsResult(kind: rkSuccess, settings: s)

  except JsonParsingError as e:
    error = """Couldn't parse json """" & path & """": """" & e.msg & """"."""
  
  except ValueError as e:
    error = """Couldn't parse json """" & path & """": """" & e.msg & """"."""
  
  except KeyError as e:
    error = """Couldn't parse json """" & path & """": """" & e.msg & """"."""
  
  except Exception as e:
    error = """Couldn't open file """" & path & """": """" & e.msg & """"."""

  if error != "":
    result = SettingsResult(kind: rkError, error: error)

proc set*[T](
  settings: Settings,
  entity: string,
  value: T
): EntityResult {.exportc, raises: [].} =
  ## Sets the field on the settings object (in-place) and saves settings to drive,
  ## gets the resulting value back
  template typeErrorMsg(type_repr, field_type_repr, entity_name: string): string = 
    "supplied value of type " & type_repr & " cannot be assigned to " & field_type_repr & " field " & entity_name

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
      if result_entity.minLength <= l <= result_entity.maxLength:
        result_entity.charVal = value
        error = ""
      else:
        error = "supplied value for " & entity & " has invalid length of " & l & ": " & value

  of ekChoice:
    error = typeErrorMsg(T.repr, "ekChoice", entity)
    when T is uint:
      if result_entity.choices.low <= value <= result_entity.choices.high:
        result_entity.choiceVal = value
      else:
        error = "no such choice in " & entity & ": " & value

  of ekSlider:
    error = typeErrorMsg(T.repr, "ekSlider", entity)
    when T is uint:
      if result_entity.minValue <= value <= result_entity.maxValue:
        result_entity.sliderVal = value
        error = ""
      else:
        error = "supplied value is not in the bounds of " & entity & ": " & value


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
): EntityResult {.exportc, raises: [].} =
  ## Gets the value from settings object
  try:
    result = EntityResult(kind: rkSuccess, entity: settings.entities[entity])
  except KeyError as e:
    result = EntityResult(kind: rkError, error: e.msg)

when isMainModule:
  import std/unittest
  from std/os import getTempDir, `/`

  proc initDb(db_json: JsonNode): string = 
    let td = getTempDir()
    let dbPath = td/"db.json"
    let f = open(dbPath, fmWrite)
    f.write(db_json.pretty)
    f.close()
    dbPath

  suite "db tests":
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
              }
          ]
      }
      let dbPath = db_json.initDb()
      var s = loadSettings(dbPath)
      case s.kind
      of rkError:
        raise newException(Exception, s.error)
      of rkSuccess:
        check(s.settings.name == "Test")


        let name = "Enable NiceSetting"
        let entityResult = s.settings.get(name)
        check(entityResult.kind == rkSuccess)
        check(entityResult.entity.kind == ekSwitch)
        check(entityResult.entity.switchVal == false)
        let er2 = s.settings.set(name, true)
        check(er2.kind == rkSuccess)
        check(er2.entity.kind == ekSwitch)
        check(er2.entity.switchVal == true)
        s = loadSettings(dbPath)
        check(s.kind == rkSuccess)
        let er3 = s.settings.get(name)
        check(er3.kind == rkSuccess)
        check(er3.entity.kind == ekSwitch)
        check(er3.entity.switchVal == true)
