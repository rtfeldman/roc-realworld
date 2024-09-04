module [UserId, gen_token, get_user_id]

import Jwt
import Request

UserId := U64
    implements [Eq, Hash, Encode, Decode]

Claims : {
    user_id : UserId,
    std_claims: Jwt.StandardClaims,
}

gen_token : Jwt.Secret, UserId, Instant -> Result Str [JwtSigningErr Jwt.SigningErr]
gen_token = \jwt_secret, user_id, now ->
	Jwt.hs256_with_claims {
		user_id,
		std_claims: { expires_at: now + Instant.hours 72 },
	}
    |> Jwt.signed_str secret
}

## parse user_id from request header
get_user_id :
    Request,
    Jwt.Secret,
    Instant
    -> Result UserId [MissingTokenHeader, InvalidJwt Jwt.ParseErr, TokenExpired]
get_user_id = \req, jwt_secret, now ->
    token_str = Request.header "Token" ? \HeaderNotFound -> MissingTokenHeader
    { claims } = Jwt.parse token_str jwt_secret ? InvalidJwt

    if claims.expires_at < now then
        Err TokenExpired
    else
        Ok claims.user_id
