module [LogLevel.* gen [to_int, to_str, equals, compare], from_str]

LogLevel := [Debug, Info, Warn, Error]
    gen from_str_case_insensitive

from_str : Str -> Result LogLevel [UnsupportedLevel]
from_str = |level_str|
    from_str_case_insensitive(level_str).map_err(|InvalidTagStr| UnsupportedLevel)
