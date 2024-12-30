module [User]

User : {
    username : Str,
    bio : Str,
    image : [Null, NotNull Str],
    following : Bool,
}
