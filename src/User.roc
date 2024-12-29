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

get_profile! : |Username| => Result User [DbErr Db.Err]
get_profile! = |username|
    user = UsersTable.first_row!(username) ? |DbErr err|
        log.err!("Database error when trying to get a user's profile. Error was: $(err.inspect())")
        DbErr(err)

    Ok(user)

login! : Str, Str => Result UserId [DbErr Db.Err]
login! = |email, password|
    user = UsersTable.first_row!(email) ? |DbErr err|
        log.err!("Database error when trying to login. Error was: $(err.inspect())")
        DbErr(err)

    if user.password == password
        Ok(user.id)
    else
        Err(DbErr(Db.Err.InvalidCredentials))
