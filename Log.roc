# This would be in a separate package, namely `log`
module [Log, Level.*, level_str, new, log, debug, info, warn, error]

Log := {
    min_level: Level,
    write!: Level, Str => {},
} generating [new]

Level := [Debug, Info, Warn, Error]
    generating [from_str_case_insensitive, to_int]
level_str : Str -> Result Level [UnsupportedLevel]
level_str = |str|
    from_str_case_insensitive(str)
    .map_err(|UnrecognizedStr| UnsupportedLevel)

log! : Log, Level, Str => {}
log! = |log, level, msg|
    if to_int(level) >= to_int(log.min_level) then
        (log.write!)(level, msg)

debug : Log, Str => {}
debug = |log, msg| log!(log, Debug, msg)

info : Log, Str => {}
info = |log, msg| log!(log, Info, msg)

warn : Log, Str => {}
warn = |log, msg| log!(log, Warn, msg)

error : Log, Str => {}
error = |log, msg| log!(log, Error, msg)
