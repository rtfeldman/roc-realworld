# Syntax Exploration

This repo is trying out experimental syntax that doesn't currently exist in Roc,
but might potentially exist someday. Part of answering the question of whether
that syntax should exist is trying it out!

## How to Run

Since this is trying out syntax that doesn't exist, this code can't be compiled or run.
The point of the repo is to try things out and see how they feel in a larger code base.

## Architecture

There is a separate README in the src/ directory that talks about the architecture of this code base.

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
- `[Foo, Bar, ..others]` instead of `[Foo, Bar]others` - planned, but not yet implemented
- String interpolation in pattern matches - planned, but not a blocker for 0.1.0
- Custom types - currently planned
- Parens-and-commas calling style - currently planned
- Static dispatch - currently planned
- `.(` - this is planned but not implemented
- Pipe-style lambdas (`|foo, bar|`) - assumed to happen if we also do parens-and-commas
- `()` instead of `{}` for the unit type - not planned, just trying it out
- `foo : () => ...` as the syntax for zero-arg function types, with `foo()` desugaring to `foo(())` - not planned, just trying it out
- Allow `|` to work in nested patterns - uncontroversially nice, but hard to implement
- Subdirectories in imports `import src/Foo` - not proposed, just trying it out
- number suffixes for units of measure, e.g. `24h` desugaring to `h(24)` - not planned, just trying it out
- Using the `?` suffix in an `expect` means "unwrap and fail if it was `Err`" - not planned, trying it out
- Allow using un-imported, package-qualified module names in expressions, e.g. `foo.Bar.baz` - not planned
- `expect ModuleName` - not proposed, just trying it out
- `test` modules - not proposed, just trying it out
