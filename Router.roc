module [Router, RouterConfig]

Router a := (Request => a)

RouterConfig ret : [
    POST Str (Request => a),
    POST1 Str RouteArg Str (Request => a),
]

init : (Request => a) -> Router a
init = \fn -> @Router fn
