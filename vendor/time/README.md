# roc-lang/time

This is a hypothetical package that provides two types: `Instant` and `Duration`.

It does not provide any effects and does not use module params. Instead,
the idea is that platforms depend on this package, and then they expose a
`Time.now!()` function which calls `Instant.from_ns_since_epoch()` under the hood,
to return an `Instant`. In this way, platforms can offer a `Time.now!()` which returns an `Instant`.

So an application would call `Time.now!()` to get the current time as an `Instant`,
and then use the operations in this package to modify instants (e.g. add or subtract
hours, minutes, etc.)
