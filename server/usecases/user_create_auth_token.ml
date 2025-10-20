open Core

type error = [ `EncryptionError of string ] [@@deriving eq, show { with_path = false }]

let run ~user ~clock =
  Jwto.encode
    Jwto.HS256
    ""
    [ "sub", Int64.to_string @@ Domains.Objects.User.id user
    ; "exp", Float.to_string @@ Eio.Time.now clock
    ]
  |> Result.map_error ~f:(Fun.const (`EncryptionError "jwt"))
;;
