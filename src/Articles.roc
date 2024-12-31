module [Articles, ArticleWithoutBody, prepare!, insert!, list!]

import DbClient
import pg.Pg.Cmd exposing [Cmd, u64]
import Article exposing [Article, NewArticle]
import UserId exposing [UserId]

import generated/Articles as ArticlesSql exposing [GetArticleBySlugRow as ArticleBySlug]
import sql/Articles/list_articles as list_articles_sql : Str
import sql/Articles/insert_article as insert_article_sql : Str
import sql/Articles/get_article_by_slug as get_article_by_slug_sql : Str

Articles := {
    db : DbClient,
    insert_article : Cmd {},
    list_articles : Cmd (List Article),
}

prepare! : DbClient => Result Articles [DbErr Db.Err]
prepare! = |client|
    Articles.{
        client,
        insert_article: client.prepare!({ name: "insert_article", sql: insert_article_sql })?,
        list_articles: client.prepare!({ name: "list_articles", sql: list_articles_sql })?,
        get_article_by_slug: client.prepare!({ name: "get_article_by_slug", sql: get_article_by_slug_sql })?,
    }

insert_sql : Str
insert_sql = "INSERT INTO articles (author_id, title, content) VALUES (?, ?, ?)"

insert! : Articles, UserId, NewArticle => Result Article [InternalErr Str]
insert! = |Articles.{ client, insert_article }, author_id, new_article|
    cmd = insert_article.bind(u64(author_id)  )

    NewArticle : {
        title : Str,
        description : Str,
        body : Str,
        tags : List Str,
    }
    client.command!(cmd)

ArticleWithoutBody : {
    slug : Str,
    title : Str,
    description : Str,
    tags: List Str,
    created_at : Str,
    updated_at : Str,
    favorited : Bool,
    favorites_count : U64,
    author : {
        username : Str,
        bio : Str,
        image_url : Str,
        following : Bool,
    }
}

get_by_slug! : Str => Result ArticleBySlug [NotFound, InternalErr Str]
get_by_slug! = |{ db, get_article_by_slug }, slug|
    when articles is
        Ok([article]) -> article
        Ok([]) -> Err(NotFound)
        Ok([..]) -> Err(InternalErr("Multiple articles found for the slug ${slug.inspect()}"))
        Err(db_err) -> Err(InternalErr(db.handle_err!(db_err)))

list! :
    Articles,
    {
        limit : U64,
        offset : U64,
        filter_by_tag : Str,
        filter_by_author : Str,
        filter_by_username_favorited : Str,
    }
    => Result (List ArticleWithoutBody) [DbErr Db.Err]
list! = |{ client, list_articles }, config|
    list_articles
    .bind([
        str config.filter_by_author,
        str config.filter_by_username_favorited,
        str config.filter_by_tag,
        u64 config.limit,
        u64 config.offset,
    ])
    .run!(client)?
    .map(|row| {
        slug: row.slug,
        title: row.title,
        description: row.description,
        created_at: row.created_at,
        updated_at: row.updated_at,
        favorited: row.favorited,
        favorites_count: row.favorites_count,
        tags: row.comma_separated_tags.split(","),
        author: {
            username: row.author_username,
            bio: row.author_bio,
            image_url: row.author_image_url,
            following: row.author_following,
        },
    })
    .Ok()
