module [Instant, from_ns_since_utc_epoch, plus, minus]

Instant := { from_ns_since_utc_epoch : U64 }

from_ns_since_utc_epoch : U64 -> Instant
from_ns_since_utc_epoch = |from_ns_since_utc_epoch|
    Instant.{ from_ns_since_utc_epoch: from_ns_since_utc_epoch }

## Enables e.g. `Clock.now!() + 24h`
plus : Instant, Duration -> Instant
plus = |instant, duration|
    Instant.{ from_ns_since_utc_epoch: instant.from_ns_since_utc_epoch + duration.to_ns() }

## Enables e.g. `Clock.now!() - 24h`
minus : Instant, Duration -> Instant
minus = |instant, duration|
    Instant.{ from_ns_since_utc_epoch: instant.from_ns_since_utc_epoch - duration.to_ns() }
