module [Db, prepare!]

import DbClient exposing [DbClient, DbConnectErr]

Db : {
    articles: Articles,
    users: Users,
}

prepare! : DbClient => Result Db [DbConnectErr, DbPrepareErr]
prepare! = |client|
    {
        articles: Articles.prepare!(client)?,
        users: Users.prepare!(client)?,
    }
