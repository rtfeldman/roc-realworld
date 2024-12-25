module [BadResponse, handleReq]

import Instant

ResponseErr : [Unauthorized, Forbidden, NotFound, BadArg, InternalErr Str]

handleReq! : Db.Conn, Jwt.Secret, Instant, Request => Result (List U8) ResponseErr
handleReq! = \db, jwtSecret, startTime, req ->
    authOptional = \handleRequest ->
        authenticateOptional startTime jwtSecret req
        |> Result.andThen handleRequest
        |> Result.map Json.encodeUtf8

    auth = \handleRequest ->
        authenticate startTime jwtSecret req
        |> Result.andThen handleRequest
        |> Result.map Json.encodeUtf8

    guest = \handleRequest -> handleRequest {} |> Result.map Json.encodeUtf8

    when Request.methodAndPath req is
        OPTIONS path -> handleCors (Request.headers req) path
        POST "/api/users/login" -> guest \{} ->
            Auth.login! db (try jsonArg req)
        GET "/articles/$(slug)" -> authOptional \optUserId ->
            Article.get! db optUserId slug
        GET "/articles" -> authOptional \optUserId ->
            Article.list! db optUserId (Request.params req)
        POST "/articles" -> auth \userId ->
            Article.insert! db userId (try jsonArg req)
        _ -> Err NotFound

jsonArg : Request -> Result a [BadArg]
    where a implements Decoding
jsonArg = \req ->
    Json.decodeUtf8 (Request.body req)
    |> Result.mapErr \_ -> BadArg

# The caller of handleReq uses this.
resultToResponse : Result _ _ -> Response
resultToResponse = \result ->
    when result is
        Ok json -> Response.ok json
        Err BadArg -> Response.err 400
        Err Unauthorized -> Response.err 401
        Err other -> Response.errWithBody 500 err

authenticate : Instant, Jwt.Secret, Request -> Result UserId [Unauthorized, BadArg]
authenticate = \now, jwtSecret, req ->
    when Auth.decodeUserId req jwtSecret now is
        Ok userId -> Ok userId
        Err (MissingToken | InvalidJwt _) -> Err BadArg
        Err TokenExpired -> Err Unauthorized

authenticateOptional : Instant, Jwt.Secret, Request -> Result [SignedIn UserId, SignedOut] [Unauthorized, BadArg]
authenticateOptional = \now, jwtSecret, req ->
    when Auth.decodeUserId req jwtSecret now is
        Ok userId -> Ok (SignedIn userId)
        Err MissingToken -> Ok SignedOut
        Err (InvalidJwt _) -> Err BadArg
        Err TokenExpired -> Err Unauthorized
