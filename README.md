# Syntax Exploration

This repo is trying out experimental syntax that doesn't currently exist in Roc,
but might potentially exist someday. Part of answering the question of whether
that syntax should exist is trying it out!

## How to Run

Since this is trying out syntax that doesn't exist, this code can't be compiled or run.
The point of the repo is to try things out and see how they feel in a larger code base.

## Dependencies

This is not using a real platform, but rather a hypothetical variant of
[basic-webserver](https://github.com/roc-lang/basic-webserver)
which requires only an `init!` function to set up the server.

For database access, this is assuming a PostgreSQL database, and uses
[Rocky the Flying Squirrel](https://github.com/stuarth/rocky-the-flying-squirrel?tab=readme-ov-file#rocky-the-flying-squirrel)
to query it.

There are some dependencies that also don't exist, which are in the `vendor/` directory with their
own READMEs.

## Syntax being explored

- `${ … }` for string interpolation - currently planned
- Parens-and-commas calling style - currently planned
- Static dispatch - currently planned
- Pipe-style lambdas (`|foo, bar|`) - assumed to happen if we also do parens-and-commas
- `then` instead of `->` for `when` branches - not planned, just wanted to see how it feels
- number suffixes for units of measure, e.g. `24h` desugaring to `h(24)` - not planned, just trying it out