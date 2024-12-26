# roc-lang/log

This is a hypothetical logging package.

The way it works is that you initialize a `Logger` with a given minimum log level and an
effectful function which writes a log message somewhere. The application author
initializes the logger (e.g. via an environment variable) and then passes the logger around
via module params so that other moduels can use it.

This all happens in main.roc in the application.
