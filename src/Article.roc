module { log, db } -> [NewArticle, Article, insert]

import Db
import ArticlesTable { db }
import Auth
import UserId exposing [UserId]

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

insert! : UserId, NewArticle => Result Article [InternalErr Str]
insert! = |author, new_article|
    article = { author, ..new_article }

    ArticlesTable.insert!(article) ? |DbErr err|
        """
        Database error when user ${user_id.to_str()} tried to post article: ${new_article.title}
        Error was: ${err.inspect()}
        """.InternalErr()

    log.info!("User ${user_id.to_str()} successfully posted a new article: ${new_article.title}")

    Ok(article)

list! : => Result (List Article) [DbErr Db.Err]
list! = ||
    list = ArticlesTable.list!() ? |DbErr err|
        log.err!("Database error when trying to list articles. Error was: ${err.inspect()}")
        DbErr err

    Ok(list)
