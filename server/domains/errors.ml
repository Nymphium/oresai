type t =
  [ `ConvertError of string
  | `EncryptionError of string
  | `DecryptionError of string
  ]
[@@deriving eq, show { with_path = false }]
