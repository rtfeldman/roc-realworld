# /api/articles endpoints.
#
# The functions in this modules take inputs from HTTP requests, use them to run
# database queries, and then translate the answers into either JSON or errors.
module [Articles, insert!, get_by_slug!, list!]

import pg.Pg.Client exposing [Client]
import pg.Pg.Cmd exposing [Cmd, u64]
import UserId exposing [UserId]
import json.Json
import ../../generated/Articles as ArticlesSql

Articles := {
    client : Client,
    prepared : ArticlesSql.PreparedArticles,
}

prepare! : Client => Result Articles DbErr
prepare! = |client|
    Ok({ client, prepared: ArticlesSql.prepare_all!(client)? })

NewArticle : {
    title : Str,
    description : Str,
    body : Str,
    tags : List Str,
}

insert! : Articles, UserId, NewArticle => Result Article [InternalErr Str]
insert! = |{ client, prepared }, author_id, new_article| {
    # TODO https://realworld-docs.netlify.app/specifications/backend/endpoints/#create-article
    # TODO make insert_article.sql etc.
    cmd = prepared.insert_article.bind(u64(author_id), ...)

    client.command!(cmd)
}

get_by_slug! : Articles, Str => Result (List U8) [NotFound, InternalErr Str]
get_by_slug! = |{ client, prepared }, slug|
    match ArticlesSql.get_article_by_slug!(client, prepared.get_article_by_slug, slug) {
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
            .encode(Json.utf8.transform(CamelCase))
            .(Ok)

        Ok([]) -> Err(NotFound)
        Ok([..]) -> Err(InternalErr("Multiple articles found for the slug ${slug.inspect()}"))
        Err(db_err) -> Err(InternalErr(db_err.inspect()))
    }

list! :
    Articles,
    [SignedIn UserId, SignedOut],
    List (Str, Str),
    => Result (List U8) [InternalErr Str]
list! = |{ client, prepared }, opt_user_id, query_params| {
    {
        limit : U64,
        offset : U64,
        filter_by_tag : Str,
        filter_by_author : Str,
        filter_by_username_favorited : Str,
    } = # TODO extract these from query params

    match
        ArticlesSql.list_articles!(
            client,
            prepared.list_articles,
            # TODO incorporate opt_user_id into the query, pass it in as nullable
            config.filter_by_author,
            config.filter_by_username_favorited,
            config.filter_by_tag,
            config.limit,
            config.offset,
        )
    {
        Ok(rows) ->
            # JSON format: https://realworld-docs.netlify.app/specifications/backend/api-response-format/#multiple-articles
            {
                articles_count: rows.len(),
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
            }
            .encode(Json.utf8.transform(CamelCase))
            .(Ok)
        Err(db_err) -> Err(InternalErr(db_err.inspect()))
    }
}

update! : Articles, UserId, Str, UpdateArticle => Result Article [NotFound, Forbidden, InternalErr Str]
update! = |{ client, prepared }, user_id, slug, update_article| {
    cmd = prepared.update_article.bind(
        update_article.title,
        update_article.description,
        update_article.body,
        slug,
        u64(user_id)
    )

    match client.query!(cmd) {
        Ok([row]) -> Article.from_row(row).(Ok)
        Ok([]) -> Err(NotFound)
        Err(db_err) -> Err(InternalErr(db_err.inspect()))
    }
}

delete! : Articles, UserId, Str => Result {} [NotFound, Forbidden, InternalErr Str]
delete! = |{ client, prepared }, user_id, slug| {
    cmd = prepared.delete_article.bind(slug, u64(user_id))

    match client.execute!(cmd) {
        Ok(0) -> Err(NotFound)
        Ok(_) -> Ok({})
        Err(db_err) -> Err(InternalErr(db_err.inspect()))
    }
}

feed! : Articles, UserId, QueryParams => Result (List U8) [InternalErr Str]
feed! = |{ client, prepared }, user_id, query_params| {
    limit = query_params.get("limit").map_ok(.to_u64()) ?? 20
    offset = query_params.get("offset").map_ok(.to_u64()) ?? 0
    cmd = prepared.get_feed.bind(u64(user_id), limit, offset)

    match client.query!(cmd) {
        Ok(rows) ->
            {
                articles_count: rows.len(),
                articles: rows.map(Article.from_row),
            }
            .encode(Json.utf8.transform(CamelCase))
            .(Ok)
        Err(db_err) ->
            Err(InternalErr(db_err.inspect()))
    }
}

favorite! : Articles, UserId, Str => Result Article [NotFound, InternalErr Str]
favorite! = |{ client, prepared }, user_id, slug| {
    # TODO after favoriting, need to run this separate query to return the article. Code sharing seems reasonable here.

    # SELECT a.*, u.username, u.bio, u.image_url,
    # (SELECT COUNT(*) FROM user_favorites uf WHERE uf.article_id = a.id) AS favorites_count
    # FROM articles a
    # JOIN users u ON a.author_id = u.id
    # WHERE a.slug = $2
    cmd = prepared.favorite_article.bind(u64(user_id), slug)

    match client.query!(cmd) {
        Ok([row]) -> Article.from_row(row).(Ok)
        Ok([]) -> Err(NotFound)
        Err(db_err) -> Err(InternalErr(db_err.inspect()))
    }
}

unfavorite! : Articles, UserId, Str => Result Article [NotFound, InternalErr Str]
unfavorite! = |{ client, prepared }, user_id, slug| {
    cmd = prepared.unfavorite_article.bind(u64(user_id), slug)

    # TODO after unfavoriting, need to run this separate query to return the article. Code sharing seems reasonable here.

      # SELECT a.*, u.username, u.bio, u.image_url,
      # (SELECT COUNT(*) FROM user_favorites uf WHERE uf.article_id = a.id) AS favorites_count
      # FROM articles a
      # JOIN users u ON a.author_id = u.id
      # WHERE a.slug = $2
    match client.query!(cmd) {
        Ok([row]) ->
            Article.fromRow(row).(Ok)
        Ok([]) ->
            Err(NotFound)
        Err(db_err) ->
            Err(InternalErr(db_err.inspect()))
    }
}
