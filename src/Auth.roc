module [login!, auth_header, authenticate, auth_optional]

import jwt.Jwt
import jwt.JwtSecret exposing [JwtSecret]
import http.Request exposing [Request]
import time.Duration exposing [hour, hours]
import UserId exposing [UserId]
import Db

## Given a user's credentials, log them in and return their UserId.
login! : Db, { email : Str, password : Str } => Result(UserId, [Unauthorized, InternalErr(Str)])
login! = |db, { email, password }| {
    match users.find_by_email!(email) {
        Ok(user) =>
            if user.password == password { # TODO decrypt, salt, etc.
                Ok(user.user_id)
            } else {
                Err(InvalidCredentials)
            }
        Err(NoRows) -> Err(Unauthorized) # Invalid credentials? 401 Unauthorized!
        Err(MultipleRows) -> Err(InternalErr("Multiple users somehow matched the email ${email}"))
        Err(DbErr(str)) -> Err(InternalErr(str))
    }
}

## Given a Request and the current time, verify that the token is valid and return its UserId.
authenticate : Request, Instant -> Result(UserId, [Unauthorized, BadArg])
authenticate = |req, now| {
    match parse_user_id(req, jwt_secret, now) {
        Ok(user_id) -> Ok(user_id)
        Err(MissingToken | InvalidJwt(_)) -> Err(BadArg)
        Err(TokenExpired) -> Err(Unauthorized)
    }
}

## Given a Request and the current time, verify that either there is a valid token (in which case
## return `SignedIn(UserId)`, or that there is no token (in which case return `SignedOut`).
auth_optional : Request, Instant -> Result([SignedIn(UserId), SignedOut], [Unauthorized, BadArg])
auth_optional = |req, now| {
    match parse_user_id(req, jwt_secret, now) {
        Ok(user_id) -> Ok(SignedIn(user_id))
        Err(MissingToken) -> Ok(SignedOut)
        Err(InvalidJwt(_)) -> Err(BadArg)
        Err(TokenExpired) -> Err(Unauthorized)
    }
}

## Parse the UserId from the request header. Used in `authenticate` and `auth_optional`.
parse_user_id :
    Request,
    JwtSecret,
    Instant,
    -> Result(UserId, [MissingTokenHeader, InvalidJwt(Jwt.ParseErr), TokenExpired])
parse_user_id = |req, jwt_secret, now| {
    token_str = Request.header("Token") ? |NotFound| MissingTokenHeader
    Jwt.{ claims } = Jwt.parse(token_str, jwt_secret) ? InvalidJwt

    if claims.expires_at < now {
        Err(TokenExpired)
    } else {
        Ok(claims.user_id)
    }
}

auth_header : UserId, JwtSecret, Instant -> (Str, Str)
auth_header = |user_id, jwt_secret, now| {
    claims = { sub: user_id.to_str(), std_claims: { expires_at: now + 12.(hours) } }
	  token_str = Jwt.hs256_with_claims(claims).signed_str(jwt_secret)

    # Auth header format: https://realworld-docs.netlify.app/specifications/backend/endpoints/
    ("Authorization", "Token ${token_str}")
}

## Request headers can be created and then succsesfully parsed back out again
expect {
    now = time.Instant.from_ns_since_utc_epoch(123456789)
    user_id = UserId.from_str(123)
    jwt_secret = JwtSecret.from_str("abcdefg")
    expired_time = now + 1.(hour)
    headers = [auth_header(user_id, jwt_secret, expired_time)]
    request = Request.new({ method: "GET", path: "/", headers })

    parse_user_id(request, jwt_secret, now) == Ok(user_id)
}

## When we get a JWT that has expired, we give an error.
expect {
    now = time.Instant.from_ns_since_utc_epoch(123456789)
    user_id = UserId.from_str(123)
    jwt_secret = JwtSecret.from_str("abcdefg")
    expired_time = now - 1.(hour)
    headers = [auth_header(user_id, jwt_secret, expired_time)]
    request = Request.new({ method: "GET", path: "/", headers })

    parse_user_id(request, jwt_secret, now) == Err(TokenExpired)
}

## When we get a request that has no JWT header in it, we get an error.
expect {
    now = time.Instant.from_ns_since_utc_epoch(123456789)
    jwt_secret = JwtSecret.from_str("abcdefg")
    request = Request.new({ method: "GET", path: "/", headers: [] })

    parse_user_id(request, jwt_secret, now) == Err(MissingTokenHeader)
}

## When we get a malformed JWT, we get a parse error.
expect {
    now = time.Instant.from_ns_since_utc_epoch(123456789)
    jwt_secret = JwtSecret.from_str("abcdefg")
    malformed_jwt = "not.a.valid.jwt"
    headers = [("Authorization", "Token ${malformed_jwt}")]
    request = Request.new({ method: "GET", path: "/", headers })

    match parse_user_id(request, jwt_secret, now) {
        Err(InvalidJwt(_)) -> True
        _ -> False
    }
}
