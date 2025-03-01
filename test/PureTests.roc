module [] # Test modules don't need to expose anything

import log.Log
import time.Instant
import time.Duration exposing [ms]

jwt_secret = "abcdefg"
log = Logger.do_nothing()
initial_time = Instant.from_ns_since_utc_epoch(123456789)

get_now = |get!, set!| {
    || {
        state = get!()
        set!({ state & now: state.now + 1ms })
        state.now
    }
}

get_db = |get!, set!, on_query!| {
    # Here, we would need roc-pg to expose a function that returns a simluated Client
    # which uses the provided `get!` and `set!` to simulate database operations.
    crash "TODO return simulated db"
}

expect |get!, set!| {
    db = get_db(get!, set!, |_|)
    now! = get_now(get!, set!)
    set!({ now: initial_time, db })

    import ../src/Route { jwt_secret, log, db, now! }

    req = Request.new({
        method: "GET",
        path: "/something-that-does-not-exist",
        headers: [],
    })

    Route.handle_req!(req) == Err(NotFound)
}

## Creating a new account should only persist encrypted password, not plaintext.
expect |get!, set!| {
    user = {
        username: "example-username",
        email: "example-email",
        password: "example-password", # TODO encrypt password
    }

    # This would run every time the database performs a query. It would send the serialized
    # query data to the on_query! function, which would then need to decode the query into
    # the expected format. This decoding step is necessary because the shape of the query
    # can vary so much. For example, an Insert query might have completely different record
    # fields depending on which table it's being inserted into. This is no problem for decoding.
    #
    # To expect multiple queries, use get! and set! to have each subsequent call to on_query!
    # pop a different function out of a List which runs on the current query. (If the list
    # is empty, fail with an error saying an unexpected query was performed.)
    on_query! = |query| {
        expect Ok(Insert({ table: "authors", ..user })) == query.decode())
        Ok(Pg.empty_query_result())
    }

    db = get_db(get!, set!, on_query!)
    now! = get_now(get!, set!)
    set!({ now: initial_time, db })

    router = Route.new({ jwt_secret, log, db, now! })

    token = "example.jwt.token" # TODO jwt from secret
    req = Request.new({
        method: "POST",
        path: "/api/users",
        headers: [],
        body: { user }.encode(Json.utf8),
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

    router.handle_req!(req).and_then(.body().decode(Json.utf8)) == Ok(expected_json)
}
