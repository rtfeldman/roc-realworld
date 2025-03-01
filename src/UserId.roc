module [UserId gen [equals, hash, encode, decode, to_str], from_u64, to_u64]

UserId := [UserId(U64)]

from_u64 : U64 -> UserId
from_u64 = |u64| UserId.(u64)

to_u64 : UserId -> U64
to_u64 = |UserId(u64)| u64
