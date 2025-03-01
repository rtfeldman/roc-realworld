# This module would be in a separate package, namely `log`
module [Logger, new, do_nothing, log!, debug!, info!, warn!, error!]

Logger := { write_raw!: LogLevel, Str => {} }

do_nothing : () -> Logger
do_nothing = || {
    Logger.{ write_raw!: |_, _| {} }
}

new : (LogLevel, Str => {}) -> Logger
new = |write_raw!| {
    Logger.{ write_raw! }
}

log! : Logger, LogLevel, Str => {}
log! = |{ write_raw! }, level, msg| {
    write_raw!(level, msg)
}

debug! : Logger, Str => {}
debug! = |log, msg| log.log!(LogLevel.Debug, msg)

info! : Logger, Str => {}
info! = |log, msg| log.log!(LogLevel.Info, msg)

warn! : Logger, Str => {}
warn! = |log, msg| log.log!(LogLevel.Warn, msg)

error! : Logger, Str => {}
error! = |log, msg| log.log!(LogLevel.Error, msg)
