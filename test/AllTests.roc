test { jwt_secret, log, db, now! } -> {
    # Test-specific package dependencies would go here, e.g. an in-memory database perhaps.
}

import log.Log

expect import PureTests

log = Logger.do_nothing() # We don't want integration tests to log anything.
jwt_secret = "abcdefg"
db = crash "TODO initialize integration test db here"
now! = ws.Time.now! # We could also use a fake "get current time" function for more reproducible tests.

expect import IntegrationTests { jwt_secret, log, db, now! }
