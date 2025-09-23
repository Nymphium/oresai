type t =
  [ `Converttion of string
  | `NotFound of string
  | `UniqueViolation of string
  ]
