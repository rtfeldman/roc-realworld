module [BadResponse, handle_req]

import Instant

BadResponse : [ ... ]

# jwt_secret is passed in from an env var/secret store/etc.
handle_req : Db.Conn, Jwt.Secret, Instant, Request => Result (List U8) BadResponse
handle_req = \db, jwt_secret, start_time, req =>
    auth_optional = \cb => authenticate_opt? start_time jwt_secret req |> cb |> to_json
    auth = \cb => authenticate? start_time jwt_secret req |> cb |> to_json
    auth_json = \cb =>
        user_id = authenticate? start_time jwt_secret req
        body = json_arg? (Request.body req)
        cb user_id body |> to_json

    when req.method_and_path is
        GET "/articles/$(slug)" => auth_optional \opt_user_id =>
            Article.get db opt_user_id slug
        GET "/articles" => auth_optional \opt_user_id =>
            Article.list db opt_user_id (Request.params req)
        POST "/articles" => auth_json \user_id, article =>
            Article.insert db user_id article

# The caller of handle_req uses this.
result_to_response : Result _ _ -> Response
result_to_Response = \result ->
    when result is
        Ok json -> Response.ok_json json
        Err BadArg -> Response.err 400
        Err Unauthorized -> Response.err 401
        Err other -> Response.err_with_body 500 err

authenticate_required : Instant, Jwt.Secret, Request -> Result UserId [Unauthorized, BadArg]
authenticate_required = \now, jwt_secret, req ->
    when Auth.get_user_id req jwt_secret now is
        Ok user_id -> Ok user_id
        Err (MissingToken | InvalidJwt _) -> Err BadArg
        Err TokenExpired -> Err Unauthorized

authenticate_opt : Instant, Jwt.Secret, Request -> Result [SignedIn UserId, SignedOut] [Unauthorized, BadArg]
authenticate_opt = \now, jwt_secret, req ->
    when Auth.get_user_id req jwt_secret now is
        Ok user_id -> Ok (SignedIn user_id)
        Err MissingToken -> Ok SignedOut
        Err (InvalidJwt _) -> Err BadArg
        Err TokenExpired -> Err Unauthorized

json_arg : a -> Result a [InvalidArgument] where a implements Decoding

to_json : Result a []err -> Result (List U8) [JsonEncodingErr Json.EncodingErr]err
    where a implements Encoding
to_json = \result ->
    Result.try result \val -> Encode.encode val, Json.utf8
