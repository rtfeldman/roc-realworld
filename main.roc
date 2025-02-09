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

init! : List Arg => Result (Request => Response) [InitFailed Str]
init! = |_args|
    jwt_secret = required_env_var!("JWT_SECRET")?

    log =
        min_level = (
            when Env.var!("LOG_LEVEL") is
                Ok(level_str) ->
                    LogLevel.from_str(level_str) ? |UnsupportedLevel|
                        InitFailed("Invalid LOG_LEVEL env var: ${level_str}")
                Err(VarNotFound) -> default_log_level
        )

        Logger.new(|level, msg| if level >= min_level then write_log!(level, msg))

    db_config = {
        host: required_env_var!("DB_HOST")?,
        user: required_env_var!("DB_USER")?,
        database: required_env_var!("DB_NAME")?,
        port:
            port_str = required_env_var!("DB_PORT")?
            port_str.to_u16() ? |InvalidNumStr| InitFailed("Invalid DB_PORT: ${port_str}")?,
        auth:
            when Env.var("DB_PASSWORD") is
                Ok(password) -> Password password
                Err(VarNotFound) -> None,
        tcp: # TODO give function(s) to do the TCP stuff it needs to do.
        on_err!: |err| log.error!("db error: ${err.inspect()}"),
    }

    db = Pg.connect!(db_config) ? |db_err| InitFailed("db connection failed: ${db_err.inspect()}")

    # TODO prepared statements need to happen here

    router = Router.{ jwt_secret, db, log, now!: ws.Clock.now! }

    Ok(|req| Router.handle_req!(router, req))

required_env_var! : Str => Result Str [InitFailed Str]
required_env_var! = |var_name|
    Env.var!(var_name).map_err(|VarNotFound| InitFailed("${var_name} env var was not set."))

write_log! : LogLevel, Str => {}
write_log! = |level, msg|
    # If writing to stderr fails when logging, ignore the error
    ws.Stderr.line!("${level.to_str()}: ${msg}") ?? {}
