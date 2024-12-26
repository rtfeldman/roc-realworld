# This module would be in a separate package, namely `log`
module [Logger.*, new, log!, debug!, info!, warn!, error!]

Logger := {
    min_level: Level,
    write_raw!: Str => {},
}

logger : Level, (Level, Str => {}) -> Logger
logger = |min_level, write_raw!|
    Logger.{ min_level, write_raw! }

log! : Logger, Level, Str => {}
log! = |log, level, msg|
    if to_int(level) >= to_int(log.min_level) then
        (log.write_raw!)(msg, level)

debug! : Logger, Str => {}
debug! = |log, msg| log.log!(Level.Debug, msg)

info! : Logger, Str => {}
info! = |log, msg| log.log!(Level.Info, msg)

warn! : Logger, Str => {}
warn! = |log, msg| log.log!(Level.Warn, msg)

error! : Logger, Str => {}
error! = |log, msg| log.log!(Level.Error, msg)
