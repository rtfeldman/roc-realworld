module { log, db } -> [User, get_profile!]

import Db
import UsersTable { db }
import Auth exposing [UserId]

User : {
    username : Str,
    bio : Str,
    image : [Null, NotNull Str],
    following : Bool,
}

get_profile! : Username => Result User [DbErr Db.Err]
get_profile! = |username|
    user = UsersTable.first_row!(username) ? |DbErr err|
        Log.err!("Database error when trying to get a user's profile. Error was: $(err.inspect())")
        DbErr(err)

    Ok(user)
