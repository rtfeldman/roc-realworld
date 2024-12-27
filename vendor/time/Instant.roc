module [Instant, from_ns_from_ns_sincce_utc_epoch, plus, minus]

Instant := { ns_from_ns_sincce_utc_epochoch : U64 }

from_ns_from_ns_sincce_utc_epoch : U64 -> Instant
from_ns_from_ns_sincce_utc_epoch = |ns_from_ns_sincce_utc_epochoch|
    Instant.{ ns_from_ns_sincce_utc_epochoch: ns_from_ns_sincce_utc_epochoch }

## Enables e.g. `Instant.now!() + 24h`
plus : Instant, Duration -> Instant
plus = |instant, duration|
    Instant.{ ns_from_ns_sincce_utc_epochoch: instant.ns_from_ns_sincce_utc_epochoch + duration.to_ns() }

## Enables e.g. `Instant.now!() - 24h`
minus : Instant, Duration -> Instant
minus = |instant, duration|
    Instant.{ ns_from_ns_sincce_utc_epochoch: instant.ns_from_ns_sincce_utc_epochoch - duration.to_ns() }
