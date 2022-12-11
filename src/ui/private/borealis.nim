{.emit: "using namespace brls::literals;".}

const
  brls = "<borealis.hpp>"

type
  ApplicationObj {.header: brls, importcpp: "brls::Application".} = object
  Application = ptr ApplicationObj

  LogLevel {.header: brls, importcpp: "brls::LogLevel".} = enum
    ERROR = 0
    WARNING = 1
    INFO = 2
    DEBUG = 3

proc t(s: string) {.header: brls, importcpp: "#brls::literals::_i18n".}
proc init() {.header: brls, importcpp: "brls::Application::init".}

# Logging
proc setLogLevel(level: LogLevel) {.header: brls, importcpp: "brls::Logger::setLogLevel".}



