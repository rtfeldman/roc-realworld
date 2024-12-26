module [Instant, from_ns_since_epoch, plus, minus]

Instant := { ns_since_epoch : U64 }

from_ns_since_epoch : U64 -> Instant
from_ns_since_epoch = |ns_since_epoch|
    Instant.{ ns_since_epoch: ns_since_epoch }

## Enables e.g. `Instant.now!() + 24h`
plus : Instant, Duration -> Instant
plus = |instant, duration|
    Instant.{ ns_since_epoch: instant.ns_since_epoch + duration.to_ns() }

## Enables e.g. `Instant.now!() - 24h`
minus : Instant, Duration -> Instant
minus = |instant, duration|
    Instant.{ ns_since_epoch: instant.ns_since_epoch - duration.to_ns() }
