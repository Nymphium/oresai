open struct
  module Caqti_error = struct
    include Caqti_error

    let equal l r = show l = show r
  end
end

type t =
  [ Caqti_error.t
  | Domains.Errors.t
  ]
[@@deriving eq, show { with_path = false }]
