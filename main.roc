app [init!] { ws: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.10.0/BgDDIykwcg51W8HA58FE_BjdzgXVk--ucv6pVb_Adik.tar.br " }

Model : { db, log, jwtSecret }

init! : => Model
init! = ||
    db = ... # get db connection
    log = ... # initialize logger

    when Env.get "JWT_SECRET" is
        Ok jwtSecret => { jwtSecret, db, log }

        Err KeyNotFound ->
            crash "Cannot start up without JWT_SECRET env var being present"

handle_request! : Request, Model => Response
handle_request! = |req, { db, log, jwt_secret }|
    import Route { req, jwt_secret, log }

    Route.handle_req!(log, db).pass_to(result_to_response)


result_to_response : Result (List U8) _ -> Response
result_to_response = |result|
    when result is
        Ok(json) -> Response.ok(json).with_header("Content-Type", "application/json; charset=utf-8")
        Err(BadArg) -> Response.err(400)
        Err(Unauthorized) -> Response.err(401)
        Err(InternalErr(str)) -> Response.err_with_body(500, str)
