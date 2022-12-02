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
    separatedAbove*: cushort
    separatedBelow*: cushort

    case kind*: EntityKind

    of ekChar:
      charVal*: string
      minLength*, maxLength*: cushort

    of ekSwitch:
      boolVal*: cushort

    of ekSlider:
      intVal*: cushort
      minValue*, maxValue*: cushort

    of ekChoice:
      uintVal*: cuint
      choices*: seq[string]

  Section* = ref object 
    name: string
    separatedAbove: cushort
    separatedBelow: cushort
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

proc loadSettings*(path: string): SettingsResult {.raises:[].} = 
  var error: string = ""
  try:
    let f = openFileStream(path)
    defer: f.close()
    let jData = parseJson(f)
    result = SettingsResult(kind: rkSuccess, settings: loadFromJson(jData))

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
): EntityResult {.exportc.} =
  ## Sets the field on the settings object (in-place) and saves settings to drive,
  ## gets the resulting value back
  EntityResult(kind: rkError, error: "Not implemented yet!")

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
                  "separatedAbove": 0,
                  "separatedBelow": 0,
                  "entities": [
                      {
                          "name": "Enable NiceSetting",
                          "helptext": "Enable this to configure app perfectly :)",
                          "separatedAbove": 0,
                          "separatedBelow": 0,
                          "kind": "ekSwitch",
                          "boolVal": 0
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
        check(entityResult.entity.boolVal == 0)
        let er2 = s.settings.set(name, 1)
        check(er2.kind == rkSuccess)
        check(er2.entity.kind == ekSwitch)
        check(er2.entity.boolVal == 1)
        s = loadSettings(dbPath)
        check(s.kind == rkSuccess)
        let er3 = s.settings.get(name)
        check(er3.kind == rkSuccess)
        check(er3.entity.kind == ekSwitch)
        check(er3.entity.boolVal == 1)
