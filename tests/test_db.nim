import unittest
import std/strformat
from std/os import getTempDir, `/`
import std/json

import db

proc initDb(db_json: JsonNode): string = 
    let td = getTempDir()
    let dbPath = td/"db.json"
    let f = open(dbPath, fmWrite)
    f.write(db_json.pretty)
    f.close()
    dbPath

test "load basic settings from file":
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
        assert s.settings.name == "Test"

test "load settings with one enitity from file":
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
                        "kind": "dkSwitch",
                        "boolVal": 1
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
        assert s.settings.name == "Test"
