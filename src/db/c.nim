import db

proc setChar*(settings: Settings, entity, value: string): EntityResult = 
    let er = set(settings, entity, value)
    case er.kind:
    of rkError:
        result = er
    of rkSuccess:
        case er.entity.kind:
        of ekChar:
            result = er
        else:
            result = EntityResult(kind: rkError, error: "wrong type returned for entity " & entity & ": " & er.entity.kind.repr)

proc setSwitch*(settings: Settings, entity: string, value: bool): EntityResult = 
    let er = set(settings, entity, value)
    case er.kind:
    of rkError:
        result = er
    of rkSuccess:
        case er.entity.kind:
        of ekChar:
            result = er
        else:
            result = EntityResult(kind: rkError, error: "wrong type returned for entity " & entity & ": " & er.entity.kind.repr)

proc setSlider*(settings: Settings, entity: string, value: uint): EntityResult = 
    let er = set(settings, entity, value)
    case er.kind:
    of rkError:
        result = er
    of rkSuccess:
        case er.entity.kind:
        of ekChar:
            result = er
        else:
            result = EntityResult(kind: rkError, error: "wrong type returned for entity " & entity & ": " & er.entity.kind.repr)

proc ekChoice*(settings: Settings, entity: string, value: bool): EntityResult = 
    let er = set(settings, entity, value)
    case er.kind:
    of rkError:
        result = er
    of rkSuccess:
        case er.entity.kind:
        of ekChar:
            result = er
        else:
            result = EntityResult(kind: rkError, error: "wrong type returned for entity " & entity & ": " & er.entity.kind.repr)
