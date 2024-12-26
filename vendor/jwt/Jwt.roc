module [Jwt, Secret, Claims, ParseErr, parse, signed_str]

Claims : {
    user_id : UserId,
    std_claims: Jwt.StandardClaims,
}

parse : Str, Secret -> Result Jwt [InvalidJwt]
parse = |str, secret|
    crash "TODO"

hs256_with_claims : Claims -> Jwt
hs256_with_claims = |claims|
    crash "TODO"

signed_str : Jwt, Secret -> Str
signed_str = |jwt, secret|
    crash "TODO"
