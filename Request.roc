# This would be in a separate `request` package.
module [Request, MethodAndPath, header, method_and_path]

Request := {
    method: Str,
    path: Str,
    headers: List (Str, Str),
}

headers : Request -> List (Str, Str)
headers = |req| req.headers

header : Request, Str -> Result Str [NotFound]
header = |req, header_name|
    for (name, value) in req.headers.iter() do
        if name == header_name
            return Ok(value)

    Err(HeaderNotFound)

MethodAndPath : [
    GET Str,
    POST Str
    PUT Str,
    DELETE Str,
    OPTIONS Str,
]

method_and_path : Request -> Result MethodAndPath [UnrecognizedMethod { method : Str, path : Str }]
method_and_path = |req|
    when method is
        "GET" -> Ok(GET req.path)
        "POST" -> Ok(POST req.path)
        "PUT" -> Ok(PUT req.path)
        "DELETE" -> Ok(DELETE req.path)
        "OPTIONS" -> Ok(OPTIONS req.path)
        _ -> Err(UnrecognizedMethod({ method: req.method, path: req.path }))
