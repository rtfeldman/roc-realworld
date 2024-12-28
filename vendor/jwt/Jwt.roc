module [Jwt, Claims, ParseErr, parse, signed_str]

import time.Instant exposing [Instant]
import JwtSecret exposing [JwtSecret]

Claims : {
    user_id : UserId,
    std_claims: {
        # TODO fill out whatever the standard JWT claims are.
        expires_at: Instant,
    },
}

parse : |Str, JwtSecret| -> Result Jwt [InvalidJwt]
parse = |str, secret|
    crash "TODO"

hs256_with_claims : |Claims| -> Jwt
hs256_with_claims = |claims|
    crash "TODO"

signed_str : |Jwt, Secret| -> Str
signed_str = |jwt, secret|
    crash "TODO"
