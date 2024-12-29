app [init!] {
    ws: platform "https://github.com/roc-lang/basic-webserver/….tar.br",
    http: "https://github.com/roc-lang/http/….tar.br",
    log: "https://github.com/roc-lang/log/….tar.br",
    time: "https://github.com/roc-lang/time/….tar.br",
    jwt: "https://github.com/…/jwt/….tar.br",
    sql: "https://github.com/stuarth/rocky-the-flying-squirrel/….tar.br",
    pg: "https://github.com/agu-z/roc-pg/….tar.br",
}

import ws.Arg
import ws.Env
import http.Request
import http.Response
import log.Log
import log.LogLevel exposing [LogLevel]
import pg.Pg

expect import test/AllTests

## This can be overridden by setting the LOG_LEVEL environment variable before running the application.
default_log_level : LogLevel
default_log_level = LogLevel.Warn

init! : |List Arg| => Result (Request => Response) [InitFailed Str]
init! = |_args|
    jwt_secret = Env.var!("JWT_SECRET") ? |VarNotFound| InitFailed("JWT_SECRET env var was not set.")
    log_level =
        when Env.var!("LOG_LEVEL") is
            Ok(level_str) ->
                LogLevel.from_str(level_str)
                ? |UnsupportedLevel| InitFailed("Invalid LOG_LEVEL env var: ${level_str}")
            Err(VarNotFound) -> default_log_level
    db = ... # TODO initialize db client

    log = Logger.new(log_level, write_log!)
    now! = ws.Time.now! # Use the platform's "get current time" function to get the current time

    import src/Route { jwt_secret, db, log, now! }

    Ok(Route.handle_req!)

write_log! : |LogLevel, Str| => {}
write_log! = |level, msg|
    # If writing to stderr fails when logging, ignore the error
    ws.Stderr.line!("${level.to_str()}: ${msg}") ?? {}
