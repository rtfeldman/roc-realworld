module [Users, find_by_username!, find_by_email!, get_profile!, login!]

import User exposing [User]

Users := { client : Client, log : Logger }

new : Client, Logger => Users
new = |client, log| { client, log }

find_by_username!: Users, Str => Result User [DbErr Str],
find_by_username! = |Users.{ client, log }, username|
    crash "TODO find by username in the db"

find_by_email!: Users, Str => Result User [DbErr Str]
find_by_email! = |Users.{ client, log }, email|
    crash "TODO find by email in the db"

get_profile! : Users, Username => Result User [NotFound, InternalErr Str]
get_profile! = |users, username|
    when users.find_by_username!(username) is
        Ok(user) => Ok(user)
        Err(NotFound) => Err(NotFound)
        Err(db_err) => Err(InternalErr("DB error when trying to get the profile for user ${username.inspect()}. Error was: $(err.inspect())"))
