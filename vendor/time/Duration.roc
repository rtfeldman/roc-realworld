# A Duration expresses the delta between two Instants.
# Durations can be used to modify Instants.
module [Duration, from_ns, to_ns, ns, ms, m, s, h, d]

Duration := { ns: U64 }

from_ns : U64 -> Duration
from_ns = |ns| Duration.{ ns }

ns : U64 -> Duration
ns = |ns| Duration.{ ns }

ms : U64 -> Duration
ms = |ms| Duration.{ ns: ms * 1_000_000 }

m : U64 -> Duration
m = |m| Duration.{ ns: m * 60_000_000_000 }

s : U64 -> Duration
s = |s| Duration.{ ns: s * 1_000_000_000 }

h : U64 -> Duration
h = |h| Duration.{ ns: h * 3_600_000_000_000 }

d : U64 -> Duration
d = |d| Duration.{ ns: d * 86_400_000_000_000 }

to_ns : Duration -> U64
to_ns = |duration| duration.ns
