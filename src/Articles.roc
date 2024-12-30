module [Articles, ArticleWithoutBody, prepare!, insert!, list!]

import DbClient
import pg.Pg.Cmd exposing [Cmd, u64]
import Article exposing [Article, NewArticle]
import UserId exposing [UserId]

Articles := {
    client : DbClient,
    insert_article : Cmd {},
    list_articles : Cmd (List Article),
}

prepare! : DbClient => Result Articles [DbErr Db.Err]
prepare! = |client|
    Articles.{
        client,
        insert_article: client.prepare!({ name: "insert_article", sql: insert_sql })?,
        list_articles: client.prepare!({ name: "list_articles", sql: list_sql })?,
        get_article_by_slug: client.prepare!({ name: "get_article_by_slug", sql: get_by_slug_sql })?,
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

get_by_slug_sql : Str
get_by_slug_sql =
    """
    SELECT
        a.slug AS slug,
        a.title AS title,
        a.description AS description,
        a.body AS body,
        a.created_at AS created_at,
        a.updated_at AS updated_at,
        a.favorited AS favorited,
        (SELECT COUNT(*) FROM user_favorites uf WHERE uf.article_id = a.article_id) AS favorites_count,
        u.username AS author_username,
        u.bio AS author_bio,
        u.image_url AS author_image_url,
        u.following AS author_following,
        string_agg(t.name, ',') AS comma_separated_tags
    FROM
        articles a
    LEFT JOIN
        users u ON a.author_id = u.user_id
    LEFT JOIN
        article_tags at ON a.article_id = at.article_id
    LEFT JOIN
        tags t ON at.tag_id = t.tag_id
    WHERE
        a.slug = $1
    GROUP BY
        a.article_id, u.user_id
    """

get_by_slug! : Str => Result { body : Str, ..ArticleWithoutBody } [InternalErr Str]
get_by_slug! = |{ client, get_article_by_slug }, slug|
    get_article_by_slug
    .bind(slug)
    .run!(client)
    .map(|row| {
        slug: row.slug,
        title: row.title,
        description: row.description,
        created_at: row.created_at,
        updated_at: row.updated_at,
        favorited: row.favorited,
        favorites_count: row.favorites_count,
        body: row.body,
        tags: row.comma_separated_tags.split(","),
        author: {
            username: row.author_username,
            bio: row.author_bio,
            image_url: row.author_image_url,
            following: row.author_following,
        },
    })

list_sql : Str
list_sql =
    """
    SELECT
        a.slug AS slug,
        a.title AS title,
        a.description AS description,
        a.created_at AS created_at,
        a.updated_at AS updated_at,
        a.favorited AS favorited,
        (SELECT COUNT(*) FROM user_favorites uf WHERE uf.article_id = a.article_id) AS favorites_count,
        u.username AS author_username,
        u.bio AS author_bio,
        u.image_url AS author_image_url,
        u.following AS author_following,
        string_agg(t.name, ',') AS comma_separated_tags
    FROM
        articles a
    LEFT JOIN
        users u ON a.author_id = u.user_id
    LEFT JOIN
        article_tags at ON a.article_id = at.article_id
    LEFT JOIN
        tags t ON at.tag_id = t.tag_id
    WHERE
        ($1 = '' OR u.username = $1)
        AND
        ($2 = '' OR EXISTS (
        SELECT 1 FROM user_favorites uf
        JOIN users u ON uf.user_id = u.user_id
        WHERE uf.article_id = a.article_id AND u.username = $2
        ))
        AND
        ($3 = '' OR EXISTS (
            SELECT 1 FROM article_tags at
            JOIN tags t ON at.tag_id = t.tag_id
            WHERE at.article_id = a.article_id AND t.name = $3
        ))
        ORDER BY a.created_at DESC
        LIMIT $4
        OFFSET $5
    ))
    GROUP BY
        a.article_id, u.user_id
    """

list! :
    Articles,
    {
        limit : U64,
        offset : U64
        filter_by_tag : Str,
        filter_by_author : Str,
        filter_by_username_favorited : Str
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
