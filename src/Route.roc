module { jwt_secret, log, db, now! } -> [handle_req!]

import http.Request exposing [Request]
import Article { log, db }
import User { log, db }
import Auth

handle_req! : Router, Request => Response
handle_req! = |req|
    method_and_path = req.method_and_path() ??
        return Response.err(400).body("Unrecognized HTTP method: ${method} ${path}")

    # Helpers for authenticating (if necessary) and/or parsing the body as JSON.
    # These are defined here so they can close over `req`.
    auth! = |handle!| Auth.authenticate(req, now!()).and_then!(handle!).pass_to(to_resp)
    auth_optional! = |handle!| Auth.auth_optional(req, now!()).and_then!(handle!).pass_to(to_resp)
    from_json! = |handle!| req.body().decode(Json.utf8).and_then!(handle!).pass_to(to_resp)
    from_json_auth! = |handle!|
        auth(req, now!())
        .and_then!(|user_id| handle!(user_id, req.body().decode(Json.utf8)?))
        .pass_to(to_resp)

    when method_and_path is
        POST "/api/users/login" ->
            from_json!(|email_and_pw| User.login!(email_and_pw))
        POST "/api/users" ->
            from_json!(|email_and_pw| User.register!(email_and_pw))
        GET "/api/user" ->
            auth!(|user_id| User.get_by_id!(user_id))
        PUT "/api/user" ->
            from_json_auth!(|user_id, user| User.update!(user_id, user))
        GET "/api/profiles/${username}" ->
            to_resp(User.get_by_username!(username))
        POST "/api/profiles/${username}/follow" ->
            auth!(|user_id| User.follow_username!(user_id, username))
        DELETE "/api/profiles/${username}/follow" ->
            auth!(|user_id| User.unfollow_username!(user_id, username))
        GET "/api/articles/${slug}" ->
            auth_optional!(|opt_user_id| Articles.get_by_slug!(opt_user_id, slug))
        GET "/api/articles" ->
            auth_optional!(|opt_user_id| Articles.list!(opt_user_id, req.params()))
        POST "/api/articles" ->
            auth_json!(|user_id, article| Article.insert!(user_id, article))
        OPTIONS path ->
            handle_cors(req.headers(), path)
        _ -> Err(NotFound)

# Internal helpers - these parse authentication headers, return appropriate error codes if
# required authentication is missing or invalid, and then encode the response as JSON.

ResponseErr : [
    BadArg,
    Unauthorized,
    Forbidden,
    NotFound,
    InternalErr(Str)
]

to_resp : Result (List U8) ResponseErr -> Response
to_resp = |result|
    when result is
        Ok(json_bytes) ->
            Response.ok()
            .body(json_bytes)
            .header("Content-Type", "application/json; charset=utf-8")
        Err(BadArg) -> Response.err(400)
        Err(Unauthorized) -> Response.err(401)
        Err(Forbidden) -> Response.err(403)
        Err(NotFound) -> Response.err(404)
        Err(InternalErr(str)) ->
            Response.err(500)
            .body(str)
            .header("Content-Type", "text/plain; charset=utf-8")
