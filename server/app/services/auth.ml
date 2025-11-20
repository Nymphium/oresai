open Effect

module Token = struct
  module Errors = struct
    type t =
      [ `DecryptionError of string
      | `EncryptionError of string
      ]
    [@@deriving eq, show { with_path = false }]
  end

  type _ t +=
    | Confirm : { token : string } -> (int64, [> `DecryptionError of string ]) Result.t t
    | Create_with_user_id :
        { user_id : int64 }
        -> (string, [> `EncryptionError of string ]) Result.t t
end
