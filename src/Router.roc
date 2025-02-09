module [Router, handle_req!]

import http.Request exposing [Request]
import Article { log, db }
import User { log, db }
import Auth

Router := {
    jwt_secret : Str,
    log : Logger,
    db : Db,
    now! : () => Instant,
}

handle_req! : Router, Request => Response
handle_req! = |{ jwt_secret, log, db, now! }, req|
    method = req.method() ??
        return Response.err(400).body("Unsupported HTTP method: ${method} (path was ${req.path().inspect()})")

    # All our valid paths start with "/api". We trim that off so we don't bother matching it later.
    path =
        when req.path().split_first("/api") is
            Ok({ before: "", after }) -> after
            _ -> return Response.err(404)

    # Helpers for authenticating (if necessary) and/or parsing the body as JSON.
    # These are defined here so they can close over `req`. If desired, helper functions
    # could extract some of this code elsewhere, but they're so short already, I didn't bother.
    auth! = |handle!| to_resp(Auth.authenticate(req, now!()).and_then!(handle!))
    auth_optional! = |handle!| to_resp(Auth.auth_optional(req, now!()).and_then!(handle!))
    from_json! = |handle!| to_resp(req.body().decode(Json.utf8).and_then!(handle!))
    from_json_auth! = |handle!|
        to_resp(
            auth(req, now!())
            .and_then!(|user_id| handle!(user_id, req.body().decode(Json.utf8)?))
        )

    when (method, path) is
        (GET, "/articles/${slug}") ->
            auth_optional!(|opt_user_id| db.articles.get_by_slug!(opt_user_id, slug))
        (GET, "/articles") ->
            auth_optional!(|opt_user_id| db.articles.list!(opt_user_id, req.params()))
        (POST, "/articles") ->
            auth_json!(|user_id, article| db.articles.insert!(user_id, article))
        (PUT, "/articles/${slug}") ->
            auth_json!(|user_id, article| db.articles.update!(user_id, slug, article))
        (DELETE, "/articles/${slug}") ->
            auth!(|user_id| db.articles.delete!(user_id, slug))
        (GET, "/articles/feed") ->
            auth!(|user_id| db.articles.feed!(user_id, req.params()))
        (POST, "/articles/${slug}/comments") ->
            auth_json!(|user_id, comment| db.comments.create!(user_id, slug, comment))
        (GET, "/articles/${slug}/comments") ->
            auth_optional!(|opt_user_id| db.comments.list!(opt_user_id, slug))
        (DELETE, "/articles/${slug}/comments/${id}") ->
            auth!(|user_id| db.comments.delete!(user_id, slug, id))
        (POST, "/articles/${slug}/favorite") ->
            auth!(|user_id| db.articles.favorite!(user_id, slug))
        (DELETE, "/articles/${slug}/favorite") ->
            auth!(|user_id| db.articles.unfavorite!(user_id, slug))
        (GET, "/tags") ->
            to_resp(db.tags.list!())
        (GET, "/profiles/${username}") ->
            to_resp(db.users.get_by_username!(username))
        (POST, "/profiles/${username}/follow") ->
            auth!(|user_id| db.users.follow_username!(user_id, username))
        (DELETE, "/profiles/${username}/follow") ->
            auth!(|user_id| db.users.unfollow_username!(user_id, username))
        (GET, "/user") ->
            auth!(|user_id| db.users.get_by_id!(user_id))
        (PUT, "/user") ->
            from_json_auth!(|user_id, user| db.users.update!(user_id, user))
        # It isn't actually necessary (or maybe even clearest) to do a nested match
        # for "POST /users/login" and "POST /users" like this, but I wanted to demo
        # how you can use normal pattern matching to apply common pieces of logic
        # to certain categories of paths and/or requests. You could also use this to
        # break out a helper function here, to handle everything under the /users path
        # (and pass the method along to it instead of matching on only POST like this).
        (POST, "/users${users_path}") ->
            from_json!(|email_and_pw|
                when users_path is
                    "/login" -> db.users.login!(email_and_pw)
                    "" -> db.users.register!(email_and_pw)
                    _ -> return Response.err(404)
            )
        (OPTIONS, path) ->
              handle_cors(req.headers(), path)
        _ -> Response.err(404)

# Internal helpers - these parse authentication headers, return appropriate error codes if
# required authentication is missing or invalid, and then encode the response as JSON.

ResponseErr : [
    BadArg,
    Unauthorized,
    Forbidden,
    NotFound,
    InternalErr(Str)
]

to_resp : Result (List U8) ResponseErr -> Task Response []
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
