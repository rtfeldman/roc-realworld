module [NewArticle, Article, insert_article]

import Db
import Auth exposing [UserId]

NewArticle : {
    title : Str,
    description : Str,
    body : Str,
    tags : List Str,
}

Article : {
    author: UserId,
    ..NewArticle,
}

insert_article : Db.Conn, NewArticle, UserId => Result Article [DbErr Db.Err]
insert_article = \db, new_article, author =>
    article = { author, ..new_article }

    ArticlesTbl.insert db article
    |> Result.map_err? \DbErr err =>
        Log.err
            """
            Database error when user $(UserId.to_str user_id) tried to post article: $(new_article.title)
            Error was: $(Inspect.to_str err)
            """
        DbErr err

    Log.info "User $(UserId.to_str user_id) successfully posted a new article: $(new_article.title)"

    Ok article
}
