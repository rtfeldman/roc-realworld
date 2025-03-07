# roc-lang/time

This is a hypothetical package that provides two types: `Instant` and `Duration`.

It does not provide any effects and does not use module params. Instead,
the idea is that platforms depend on this package, and then they expose a
`Clock.now!()` function which calls `Instant.from_ns_since_utc_epoch()` under the hood,
to return an `Instant`. In this way, platforms can offer a `Clock.now!()` which returns an `Instant`.

So an application would call `Clock.now!()` to get the current time as an `Instant`,
and then use the operations in this package to modify instants (e.g. add or subtract
hours, minutes, etc.)
