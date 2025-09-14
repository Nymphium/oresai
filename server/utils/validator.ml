type 'a t =
  { report : 'a -> string
  ; validate : 'a -> bool
  }
[@@deriving make]
