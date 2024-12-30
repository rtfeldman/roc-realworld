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

get_profile! : Username => Result User [NotFound, InternalErr Str]
get_profile! = |username|
    when db.users.find_by_username!(username) is
        Ok(user) => Ok(user)
        Err(NotFound) => Err(NotFound)
        Err(db_err) => Err(InternalErr("DB error when trying to get the profile for user ${username.inspect()}. Error was: $(err.inspect())"))

login! : Str, Str => Result UserId [InvalidCredentials, InternalErr Str]
login! = |email, password|
    when db.users.find_by_email!(email) is
        Ok(user) =>
            if user.password == password then # TODO decrypt, salt, etc.
                Ok(user.user_id)
            else
                Err(InvalidCredentials)
        Err(db_err) => Err(InternalErr("DB error when trying to find password for email ${email.inspect()}. Error was: $(err.inspect())"))
