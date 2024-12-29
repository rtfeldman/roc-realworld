# This module would be in a separate package, namely `log`
module [Logger.*, new, do_nothing, log!, debug!, info!, warn!, error!]

Logger := {
    min_level: Level,
    write_raw!: Level, Str => {},
}

do_nothing : -> Logger
do_nothing = ||
    Logger.{ min_level: Level.Info, write_raw!: |_, _| {} }

new : Level, (Level, Str => {}) -> Logger
new = |min_level, write_raw!|
    Logger.{ min_level, write_raw! }

log! : Logger, Level, Str => {}
log! = |log, level, msg|
    if to_int(level) >= to_int(log.min_level) then
        (log.write_raw!)(level, msg)

debug! : Logger, Str => {}
debug! = |log, msg| log.log!(Level.Debug, msg)

info! : Logger, Str => {}
info! = |log, msg| log.log!(Level.Info, msg)

warn! : Logger, Str => {}
warn! = |log, msg| log.log!(Level.Warn, msg)

error! : Logger, Str => {}
error! = |log, msg| log.log!(Level.Error, msg)
