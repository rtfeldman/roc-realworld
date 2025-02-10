# This would be in a separate `request` package.
module [Request, Method, new, header]

Request := {
    method: Str,
    path: Str,
    headers: List (Str, Str),
}

## All the HTTP methods we support.
Method : [GET, POST, PUT, DELETE, OPTIONS]

new : { method : Str, path : Str, headers : List (Str, Str) } -> Request
new = |{ method, path, headers }| Request.{ method, path, headers }

header : Request, Str -> Result Str [NotFound]
header = |req, _header_name|
    for (name, value) in req.headers.iter() do
        if name == header_name then
            return Ok(value)

    Err(HeaderNotFound)

path : Request -> Str
path = |req| req.path

method : Request -> Result Method [UnrecognizedMethod(Str)]
method = |req|
    when req.method is
        "GET" -> Ok(GET)
        "POST" -> Ok(POST)
        "PUT" -> Ok(PUT)
        "DELETE" -> Ok(DELETE)
        "OPTIONS" -> Ok(OPTIONS)
        _ -> Err(UnrecognizedMethod(req.method))

params : Request -> List (Str, Str)
params = |req|
    req
    .path()
    .split_first("?")
    .map_ok(.after)
    .with_default("")
    .split_on("&")
    .map(|param|
        when param.split_first("=") is
            Ok({ before, after }) -> (before, after)
            Err(NotFound) -> (param, "")
    )

params : Request -> List (Str, Str)
params = |req|
    req
    .path()
    .split_first("?")
    .map_ok(.get_1())
    .with_default("")
    .split_on("&")
    .map(|param| param.split_first("=") ?? (param, ""))
