# /api/articles endpoints
module { db } -> [insert!, get_by_slug!, list!]

import DbClient
import pg.Pg.Cmd exposing [Cmd, u64]
import UserId exposing [UserId]
import json.Json
import ../../generated/Articles as ArticlesSql

insert! : UserId, NewArticle => Result Article [InternalErr Str]
insert! = |author_id, new_article|
    # TODO https://realworld-docs.netlify.app/specifications/backend/endpoints/#create-article
    # TODO make insert_article.sql etc.
    cmd = db.articles.insert_article.bind(u64(author_id), ...)

    NewArticle : {
        title : Str,
        description : Str,
        body : Str,
        tags : List Str,
    }
    client.command!(cmd)

get_by_slug! : Str => Result (List U8) [NotFound, InternalErr Str]
get_by_slug! = |slug|
    when ArticlesSql.get_article_by_slug!(db.client, db.articles.get_article_by_slug, slug) is
        Ok([row]) ->
            {
                slug: row.slug,
                title: row.title,
                description: row.description,
                body: row.body,
                created_at: row.created_at,
                updated_at: row.updated_at,
                favorited: row.favorited,
                favorites_count: row.favorites_count,
                tag_list: row.comma_separated_tags.split(","),
                author: {
                    username: row.author_username,
                    bio: row.author_bio,
                    image_url: row.author_image_url,
                    following: row.author_following,
                },
            })
            .encode(Json.utf8_with({ transform: CamelCase }))
            .Ok()
        Ok([]) -> Err(NotFound)
        Ok([..]) -> Err(InternalErr("Multiple articles found for the slug ${slug.inspect()}"))
        Err(db_err) -> Err(InternalErr(db.handle_err!(db_err)))

list! :
    [SignedIn UserId, SignedOut],
    List (Str, Str),
    => Result (List U8) [InternalErr Str]
list! = |opt_user_id, query_params|
    {
        limit : U64,
        offset : U64,
        filter_by_tag : Str,
        filter_by_author : Str,
        filter_by_username_favorited : Str,
    } = # TODO extract these from query params

    when
        ArticlesSql.list_articles!(
            # TODO incorporate opt_user_id into the query, pass it in as nullable
            config.filter_by_author,
            config.filter_by_username_favorited,
            config.filter_by_tag,
            config.limit,
            config.offset,
        )
    is
        Ok(rows) ->
            # JSON format: https://realworld-docs.netlify.app/specifications/backend/api-response-format/#multiple-articles
            {
                articles: rows.map(|row| {
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
                }),
                articles_count: rows.len(),
            }
            .encode(Json.utf8_with({ transform: CamelCase }))
            .Ok()
      Err(db_err) -> Err(InternalErr(db.handle_err!(db_err)))
