# Let's pretend this was generated by https://github.com/stuarth/rocky-the-flying-squirrel
# (it wasn't, because part of what this repo is exploring is using prepared statements -
# which is not what Rocky generates as of this writing!)
module [
    PreparedArticles,
    ListArticlesRow,
    GetArticleBySlugRow,
    prepare_all!,
    prepare_list_articles!,
    list_articles!,
    get_article_by_slug!
]

import pg.Pg.Client
import pg.Pg.Cmd
import pg.Pg

PreparedArticles : {
    list_articles: Cmd (List ListArticlesRow),
    get_article_by_slug: Cmd GetArticleBySlugRow,
}

prepare_all! :
    Client
    => Result
        PreparedArticles
        [
            PgExpectErr _,
            PgErr Pg.Error,
            PgProtoErr _,
            TcpReadErr _,
            TcpUnexpectedEOF,
            TcpWriteErr _,
        ]
prepare_all! = |client|
    {
        list_articles: prepare_list_articles!(client)?,
        get_article_by_slug: prepare_get_article_by_slug!(client)?,
    }

# list_articles.sql

ListArticlesRow : {
    slug: Str,
    title: Str,
    description: Str,
    created_at: Str,
    updated_at: Str,
    favorited: Bool,
    favorites_count: U64,
    tag_list: List Str,
    author: {
        username: Str,
        bio: Str,
        image_url: Str,
        following: Bool,
    }
}

prepare_list_articles! :
    Client
    => Result
        (Cmd (List ListArticlesRow))
        [
            PgExpectErr _,
            PgErr Pg.Error,
            PgProtoErr _,
            TcpReadErr _,
            TcpUnexpectedEOF,
            TcpWriteErr _,
        ]
prepare_list_articles! = |client|
    import "../src/sql/Articles/list_articles.sql" as sql : Str
    client.prepare("list_articles", sql)

list_articles! :
    Pg.Client,
    Pg.Cmd (List ListArticlesRow),
    Str,
    Str,
    Str,
    U64,
    U64
    => Result
        (List ListArticlesRow)
        [
            PgExpectErr _,
            PgErr Pg.Error,
            PgProtoErr _,
            TcpReadErr _,
            TcpUnexpectedEOF,
            TcpWriteErr _,
        ]
list_articles! = |client, cmd, p0, p1, p2, p3, p4|
    client.command!(cmd.bind([Cmd.str p0, Cmd.str p1, Cmd.str p2, Cmd.u64 p3, Cmd.u64 p4]))

# get_article_by_slug.sql

GetArticleBySlugRow : {
    slug : Str,
    title : Str,
    description : Str,
    tag_list: List Str,
    created_at : Str,
    updated_at : Str,
    favorited : Bool,
    favorites_count : U64,
    body : Str,
    author : {
        username : Str,
        bio : Str,
        image_url : Str,
        following : Bool,
    }
}

prepare_get_article_by_slug! :
    Pg.Client,
    Pg.Cmd (GetArticleBySlugRow),
    Str,
    => Result
        GetArticleBySlugRow
        [
            PgExpectErr _,
            PgErr Pg.Error,
            PgProtoErr _,
            TcpReadErr _,
            TcpUnexpectedEOF,
            TcpWriteErr _,
        ]
prepare_get_article_by_slug! = |client, cmd, p0|
    import "../src/sql/Articles/get_article_by_slug.sql" as sql : Str
    client.prepare("get_article_by_slug", sql)

get_article_by_slug! :
    Pg.Client,
    Pg.Cmd (GetArticleBySlugRow),
    Str,
    => Result
        GetArticleBySlugRow
        [
            PgExpectErr _,
            PgErr Pg.Error,
            PgProtoErr _,
            TcpReadErr _,
            TcpUnexpectedEOF,
            TcpWriteErr _,
        ]
get_article_by_slug! = |client, cmd, p0|
    client.command!(cmd.bind([Cmd.str p0]))
