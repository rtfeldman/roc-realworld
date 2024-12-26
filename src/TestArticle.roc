
expect |get!, set!|
    userId = UserId.fromU64 42
    article = {
        title: "foo",
        description: "bar",
        body: "baz",
        tags: []
    }
    set! { expectedDb: [InsertArticle userId article] }
    pop! = \{} =>
        when List.splitFirst (get! {}).expectedDb is
            Ok (first, rest) ->
                set! { expectedDb: rest }
                Ok first

            Err ListWasEmpty ->
                Err EmptyExpectationList

    fakeInsert = \table, data ->
        when pop! {} is
            Ok (InsertArticle insertedUserId insertedArticle) ->
                expect insertUserId == userId
                expect insertedArticle == insertedArticle

    db = Db.fake { insert: fakeInsert }
    log = ???
    import Article { log, db }

    result = Article.insertArticle! article


insertArticle! : Db.Conn, UserId, NewArticle => Result Article [InternalErr Str]
insertArticle! = \db, author, newArticle ->
    article = { author, ..newArticle }

    try ArticlesTable.insert! db article ? \DbErr err ->
        InternalErr
            """
            Database error when user $(UserId.toStr userId) tried to post article: $(newArticle.title)
            Error was: $(Inspect.toStr err)
            """
        InternalErr "Database error when trying to post article."

    Log.info! "User $(UserId.toStr userId) successfully posted a new article: $(newArticle.title)"

    Ok article
