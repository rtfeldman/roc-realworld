DbUsers := { db: Db }

new : Db => DbUsers,
new = |db| { db: db }

find_by_username!: DbUsers, Str => Result User [DbErr Str],
find_by_username! = |DbUsers.{ db }, username|
    crash "TODO find by username in the db"

find_by_email!: DbUsers, Str => Result User [DbErr Str]
find_by_email! = |DbUsers.{ db }, email|
    crash "TODO find by email in the db"
