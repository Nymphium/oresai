type t =
  [ `ConvertError of string
  | `EncryptionError of string
  | `DecryptionError of string
  | `NotFound of string * string (* resource * id *)
  | `DuplicateEntry of string * string (* resource * id *)
  | `ReferenceError of string * string (*  resource * id *)
  | `InternalError of string
  ]
[@@deriving eq, show { with_path = false }]
