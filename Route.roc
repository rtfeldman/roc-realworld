module { jwt_secret, log, db } -> [ResponseErr, handle_req]

import req.Request exposing [Request]
import Instant
import Article { log, db }
import Auth { log, db }
import User { log, db }

ResponseErr : [Unauthorized, Forbidden, NotFound, BadArg Str, InternalErr Str]

handle_req! : Request => Result (List U8) ResponseErr
handle_req! = |req|
    method_and_path = req.method_and_path() ? |UnrecognizedMethod { method, path }|
        BadArg("Unrecognized HTTP method: ${method} ${path}")

    when method_and_path is
        POST "/api/users/login" ->
            guest_json!(|creds| User.login!(creds))
        POST "/api/users" ->
            guest_json!(|creds| User.register!(creds))
        GET "/api/user" ->
            auth!(|user_id| User.get_by_id!(user_id))
        PUT "/api/user" ->
            auth_json!(|user_id, user| User.update!(user_id, user))
        GET "/api/profiles/${username}" ->
            guest!(|| User.get_by_username!(username))
        POST "/api/profiles/${username}/follow" ->
            auth!(|user_id| User.follow_username!(user_id, username))
        DELETE "/api/profiles/${username}/follow" ->
            auth!(|user_id| User.unfollow_username!(user_id, username))
        GET "/api/articles/${slug}" ->
            auth_optional!(req, |opt_user_id| Article.get!(opt_user_id, slug))
        GET "/api/articles" ->
            auth_optional!(req, |opt_user_id| Article.list!(opt_user_id, req.params()))
        POST "/api/articles" ->
            auth_json!(|user_id, article| Article.insert!(user_id, article))
        OPTIONS path ->
            handle_cors(req.headers(), path)
        _ -> Err(NotFound)

# Request Helpers - these parse authentication headers, return appropriate error codes if
# required authentication is missing or invalid, and then encode the response as JSON.

auth_optional! :
    Request,
    ([SignedIn UserId, SignedOut] => Result val [..errors] where val.[Encode])
    => Result (List U8) [Unauthorized, BadArg, ..errors]
auth_optional! = |req, handle!|
    authenticate_optional(req, Instant.now!())
    .and_then!(handle!)
    .map(Json.encode_utf8)

auth! :
    Request,
    (UserId => Result val [..errors] where val.[Encode])
    => Result (List U8) [Unauthorized, BadArg, ..errors]
auth! = |req, handle!|
    authenticate(Instant.now!())
    .and_then!(handle!)
    .map(Json.encode_utf8)

guest! :
    Request,
    (=> Result val [..errors] where val.[Encode])
    => Result (List U8) [Unauthorized, BadArg, ..errors]
guest! = |req, handle!|
    handle!()
    .map(Json.encode_utf8)
