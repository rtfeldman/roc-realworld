module [NewArticle, Article]

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
