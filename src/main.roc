app [init!] {
    ws: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.10.0/BgDDIykwcg51W8HA58FE_BjdzgXVk--ucv6pVb_Adik.tar.br",
    http: "https://github.com/roc-lang/http/.tar.br",
    log: "https://github.com/roc-lang/log/.tar.br",
    time: "https://github.com/roc-lang/time/.tar.br",
    jwt: "https://github.com/…/jwt/.tar.br",
    sql: "https://github.com/stuarth/rocky-the-flying-squirrel/.tar.br",
    pg: "https://github.com/agu-z/roc-pg/.tar.br",
}

import ws.Arg
import ws.Env
import ws.Stderr
import http.Request
import http.Response
import log.Log
import log.LogLevel exposing [LogLevel]
import pg.Pg

## This can be overridden by setting the LOG_LEVEL environment variable.
default_log_level : LogLevel
default_log_level = LogLevel.Warn

init! : List Arg => Result (Request => Response) [InitFailed Str]
init! = |_args|
    jwt_secret = Env.var!("JWT_SECRET") ? |VarNotFound| InitFailed("JWT_SECRET env var was not set.")
    log_level =
        when Env.var!("LOG_LEVEL") is
            Ok(level_str) ->
                LogLevel.from_str(level_str)
                ? |UnsupportedLevel| InitFailed("Invalid LOG_LEVEL env var: ${level_str}")
            Err(VarNotFound) -> default_log_level
    db = ... # TODO initialize db client

    import Route { jwt_secret, db, log: Log.logger(log_level, write_log!) }

    Ok(|req| Route.handle_req!(req).pass_to(make_response))

make_response : Result (List U8) Route.ResponseErr -> Response
make_response = |result|
    when result is
        Ok(json) -> Response.ok(json).with_header("Content-Type", "application/json; charset=utf-8")
        Err(BadArg) -> Response.err(400)
        Err(Unauthorized) -> Response.err(401)
        Err(Forbidden) -> Response.err(403)
        Err(NotFound) -> Response.err(404)
        Err(InternalErr(str)) -> Response.err_with_body(500, str)

write_log! : LogLevel, Str => {}
write_log! = |level, msg|
    # If writing to stderr fails when logging, ignore the error
    Stderr.line!("${level.to_str()}: ${msg}") ?? {}
