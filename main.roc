app [init!] {
    ws: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.10.0/BgDDIykwcg51W8HA58FE_BjdzgXVk--ucv6pVb_Adik.tar.br",
    req: "https://github.com/roc-lang/http-request/.tar.br",
    resp: "https://github.com/roc-lang/http-response/.tar.br",
    log: "https://github.com/roc-lang/log/.tar.br",
    pg: "https://github.com/agu-z/roc-pg/.tar.br",
}

import ws.Arg
import ws.Env
import ws.Stderr
import req.Request
import resp.Response
import log.Log
import pg.Pg

init! : List Arg => Result (Request => Response) [InitFailed Str]
init! = |_args|
    jwt_secret = Env.var!("JWT_SECRET") ? |VarNotFound| InitFailed("JWT_SECRET env var was not set.")
    log_level =
        when Env.var!("LOG_LEVEL") is
            Ok(level_str) ->
                Log.level_str(level_str)
                ? |UnsupportedLevel| InitFailed("Invalid LOG_LEVEL env var: ${level_str}")
            Err(VarNotFound) -> Log.Info
    log = Log.new(log_level, Stderr.line!)

    db = ... # TODO follow the example in https://github.com/agu-z/roc-pg/blob/92374e8c00390839a1ae2aa50abb8230ad9e81c3/examples/store/server.roc

    import Route { jwt_secret, db, log }

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
