## A wrapper around a roc-pg Client which automatically logs database errors.
## (This could just as easily send other observability events, too - spans, traces, etc.)
module [DbClient, DbConnectErr, connect!, command!, batch!, prepare!, handle_err!]

import pg.PgClient exposing [Client]

DbClient := {
    client: Client,
    on_err!: DbErr => {},
}

DbConnectErr : [
    PasswordRequired,
    UnsupportedAuth,
    PgProtoErr [UnexpectedMsg Str]
]

connect! :
    {
        host : Str,
        port : U16,
        user : Str,
        auth : [None, Password Str],
        database : Str,
        on_err! : DbErr => {},
    },
    => Result Db DbConnectErr
connect! = |{ host, port, user, auth, database, on_err! }|
    client = Client.connect!({ host, port, user, auth, database })
    users = DbUsers.new(client)
    Db.{ client, on_err!, users }

command! : Db, Cmd a err => Result a [DbErr Str]
command! = |db, cmd|
    Client.command!(db.client, cmd).map_err!(|err| handle_err!(db, err))

batch! : Db, Batch a err => Result a [DbErr Str]
batch! = |db, cmd|
    Client.batch!(db.client, cmd).map_err!(|err| handle_err!(db, err))

prepare! : Db, { name : Str, sql : Str } => Result a [DbErr Str]
prepare! = |db, { name, sql }|
    Client.prepare!(sql, { name, client: db.client }).map_err!(|err| handle_err!(db, err))

on_err = Db -> (DbErr => [DbErr Str])
on_err = |db| |db_err| handle_err!(db, db_err)

## Helper function to run db.on_err! and then return db_err.inspect()
handle_err! = Db, DbErr => Str
handle_err! = |db, db_err|
    (db.on_err!)(db_err)
    db_err.inspect()
