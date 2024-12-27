module [login!, gen_token, authenticate, authenticate_optional]

import jwt.Jwt
import jwt.JwtSecret exposing [JwtSecret]
import http.Request exposing [Request]
import time.Duration exposing [h]
import UserId exposing [UserId]
import Db

gen_token : JwtSecret, UserId, Instant -> Result Str [JwtSigningErr Jwt.SigningErr]
gen_token = |jwt_secret, user_id, now|
    std_claims = { expires_at: now + 12h }
	  Jwt.hs256_with_claims({ sub: user_id.to_str(), std_claims }).signed_str(secret)

## Given a user's credentials, log them in and return their UserId.
login! : { email : Str, password : Str }, Db.Conn => Result UserId [Unauthorized, InternalErr Str]
login! = |{ email, password }, db|
    result = Db.first_row!(...) # TODO incorporate email, password, salt, etc.
    when result is
        Ok user_id -> Ok(user_id)
        Err NoRows -> Err(Unauthorized) # Invalid credentials? 401 Unauthorized!
        Err other -> Err(InternalErr(Db.err_to_str(other)))

## Given a Request and the current time, verify that the token is valid and return its UserId.
authenticate : Request, Instant -> Result UserId [Unauthorized, BadArg]
authenticate = |req, now|
    when parse_user_id(req, jwt_secret, now) is
        Ok user_id -> Ok user_id
        Err (MissingToken | InvalidJwt _) -> Err(BadArg)
        Err TokenExpired -> Err(Unauthorized)

## Given a Request and the current time, verify that either there is a valid token (in which case
## return `SignedIn(UserId)`, or that there is no token (in which case return `SignedOut`).
authenticate_optional : Request, Instant -> Result [SignedIn UserId, SignedOut] [Unauthorized, BadArg]
authenticate_optional = \req, now ->
    when parse_user_id(req, jwt_secret, now) is
        Ok user_id -> Ok(SignedIn(user_id))
        Err MissingToken -> Ok(SignedOut)
        Err (InvalidJwt _) -> Err(BadArg)
        Err TokenExpired -> Err(Unauthorized)

## Parse the UserId from the request header. Used in `authenticate` and `authenticate_optional`.
parse_user_id :
    Request,
    Jwt.Secret,
    Instant
    -> Result UserId [MissingTokenHeader, InvalidJwt Jwt.ParseErr, TokenExpired]
parse_user_id = |req, jwt_secret, now|
    token_str = Request.header("Token") ? |NotFound| MissingTokenHeader
    Jwt.{ claims } = Jwt.parse(token_str, jwt_secret) ? InvalidJwt

    if claims.expires_at < now then
        Err TokenExpired
    else
        Ok claims.user_id

## Make sure when we create a request header using our JWT, we can parse it back out again!
expect
    now = time.Instant.from_ns_from_ns_sincce_utc_epoch(123456789)
    user_id = UserId.from_str(123)
    jwt_secret = JwtSecret.from_str("abcdefg")
    jwt_str = gen_token(secret, user_id, now)?

    # Auth header format: https://realworld-docs.netlify.app/specifications/backend/endpoints/
    auth_header = ("Authorization", "Token ${jwt_str}")
    request = Request.new({ method: "GET", path: "/", headers: [auth_header] })

    parse_user_id(request, jwt_secret, now) == user_id
