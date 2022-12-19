import db

proc setChar*(settings: Settings, entity, value: string): EntityResult {.raises: [], exportc.} =
  let er = set(settings, entity, value)
  case er.kind:
  of rkError:
    result = er
  of rkSuccess:
    case er.entity.kind:
    of ekChar:
      result = er
    else:
      result = EntityResult(kind: rkError,
              error: "wrong type returned for entity " & entity & ": " &
              er.entity.kind.repr)

proc setSwitch*(settings: Settings, entity: string, value: bool): EntityResult {.raises: [], exportc.} =
  let er = set(settings, entity, value)
  case er.kind:
  of rkError:
    result = er
  of rkSuccess:
    case er.entity.kind:
    of ekSwitch:
      result = er
    else:
      result = EntityResult(kind: rkError,
              error: "wrong type returned for entity " & entity & ": " &
              er.entity.kind.repr)

proc setSlider*(settings: Settings, entity: string, value: uint): EntityResult {.raises: [], exportc.} =
  let er = set(settings, entity, value)
  case er.kind:
  of rkError:
    result = er
  of rkSuccess:
    case er.entity.kind:
    of ekSlider:
      result = er
    else:
      result = EntityResult(kind: rkError,
              error: "wrong type returned for entity " & entity & ": " &
              er.entity.kind.repr)

proc setChoice*(settings: Settings, entity: string, value: uint): EntityResult {.raises: [], exportc.} =
  let er = set(settings, entity, value)
  case er.kind:
  of rkError:
    result = er
  of rkSuccess:
    case er.entity.kind:
    of ekChoice:
      result = er
    else:
      result = EntityResult(kind: rkError,
              error: "wrong type returned for entity " & entity & ": " &
              er.entity.kind.repr)

when isMainModule:
  import std/unittest
  import std/json
  from std/os import getTempDir, `/`

  proc initDb(db_json: JsonNode): string =
    let td = getTempDir()
    let dbPath = td/"db.json"
    let f = open(dbPath, fmWrite)
    f.write(db_json.pretty)
    f.close()
    dbPath

  suite "db tests":
    test "test fields writing correctly":
      var
        sr: SettingsResult
        er: EntityResult
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
      let db_path = initDb(db_json)
      sr = loadSettings(dbPath)
      case sr.kind
      of rkError:
        raise newException(Exception, sr.error)
      of rkSuccess:
        check(sr.settings.name == "Test")

        er = sr.settings.setSwitch("Enable NiceSetting", true)
        check(er.kind == rkSuccess)
        check(er.entity.switchVal == true)
        er = sr.settings.setChar("Enable NiceSetting 2", "Testing...")
        check(er.kind == rkSuccess)
        check(er.entity.charVal == "Testing...")
        er = sr.settings.setChoice("Enable NiceSetting 3", 1)
        check(er.kind == rkSuccess)
        check(er.entity.choiceVal == 1)
        er = sr.settings.setSlider("Enable NiceSetting 4", 4)
        check(er.kind == rkSuccess)
        check(er.entity.sliderVal == 4)
