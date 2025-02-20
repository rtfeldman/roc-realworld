module { client, log } -> [Users, find_by_username!, find_by_email!, get_profile!, login!]

User : {
    username : Str,
    bio : Str,
    image : [Null, NotNull Str],
    following : Bool,
}

find_by_username!: Str => Result User [DbErr Str],
find_by_username! = |username|
    crash "TODO find by username in the db"

find_by_email!: Str => Result User [DbErr Str]
find_by_email! = |email|
    crash "TODO find by email in the db"

get_profile! : Username => Result User [NotFound, InternalErr Str]
get_profile! = |username|
    match find_by_username!(username) {
        Ok(user) { Ok(user) },
        Err(NotFound) { Err(NotFound) },
        Err(db_err) {
            Err(InternalErr("DB error when trying to get the profile for user ${username.inspect()}. Error was: $(err.inspect())"))
        },
    }
