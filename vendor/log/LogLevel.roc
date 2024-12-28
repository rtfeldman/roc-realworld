module [LogLevel.*, from_str, gen to_int, to_str]

LogLevel := [Debug, Info, Warn, Error]
    gen from_str_case_insensitive

from_str : |Str, (|Str| => {})| -> Result Level [UnsupportedLevel]
from_str = |level_str, write_raw!|
    when from_str_case_insensitive(level_str) is
        Ok min_level -> Log.{ min_level, write_raw! }
        Err UnrecognizedStr -> Err UnsupportedLevel
