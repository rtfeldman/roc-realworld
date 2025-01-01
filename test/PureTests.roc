module [] # Test modules don't need to expose anything

import log.Log
import time.Instant
import time.Duration exposing [ms]

jwt_secret = "abcdefg"
log = Logger.do_nothing()
initial_time = Instant.from_ns_since_utc_epoch(123456789)

get_now = |get!, set!| ||
    state = get!()
    set!({ state & now: state.now + 1ms })
    state.now

get_db = |get!, set!|
    # TODO return in-memory db

expect |get!, set!|
    db = get_db(get!, set!)
    now! = get_now(get!, set!)
    set!({ now: initial_time, db })

    import ../src/Route { jwt_secret, log, db, now! }

    req = Request.new({
        method: "GET",
        path: "/something-that-does-not-exist",
        headers: [],
    })

    Route.handle_req!(req) == Err(NotFound)

## Creating a new account should only persist encrypted password, not plaintext.
expect |get!, set!|
    db = get_db(get!, set!)
    now! = get_now(get!, set!)
    set!({ now: initial_time, db })

    # TODO make db do the simulation

    import ../src/Route { jwt_secret, log, db, now! }

    username = "example-username"
    email = "example-email"
    password = "example-password"
    token = "example.jwt.token" # TODO jwt from secret
    req = Request.new({
        method: "POST",
        path: "/api/users",
        headers: [],
        body: { user: { username, email, password } }.encode(Json.utf8),
    })

    expected = {
        user: {
            email,
            username,
            token,
            bio,
            image,
        }
    }

    Route.handle_req!(req).and_then(.body().decode(Json.utf8)) == Ok(expected_json)
