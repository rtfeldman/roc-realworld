# Just an opaque wrapper around a string, so these don't get confused with normal strings.
module [Secret.* gen [to_str, from_str, equals, hash, compare, encode, decode]]

Secret := Str
