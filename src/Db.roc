module [Db, prepare!]

import DbClient exposing [DbClient, DbConnectErr]

import ../generated/Articles
import ../generated/Users

Db : {
    client: DbClient,
    articles: Articles.PreparedStatements,
    users: Users.PreparedStatements,
}

prepare! : DbClient => Result Db [DbConnectErr, DbPrepareErr]
prepare! = |client|
    {
        articles: Articles.prepare_all!(client)?,
        users: Users.prepare_all!(client)?,
    }
