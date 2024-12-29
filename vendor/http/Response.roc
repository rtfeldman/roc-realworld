module [Response, ok, err, with_body, with_header]

# ok : Str -> Response
# ok = |body| -> Response.ok(body).with_header("Content-Type", "application/json; charset=utf-8")

# make_response = |result|
#     when result is
#         Ok(json) -> Response.ok(json).with_header("Content-Type", "application/json; charset=utf-8")
#         Err(BadArg) -> Response.err(400)
#         Err(Unauthorized) -> Response.err(401)
#         Err(Forbidden) -> Response.err(403)
#         Err(NotFound) -> Response.err(404)
#         Err(InternalErr(str)) -> Response.err(500).with_body(str)
