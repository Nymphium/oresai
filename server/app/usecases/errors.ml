type t =
  [ Domains.Errors.t
  | Get_user_by_email.error
  | Get_user_by_id.error
  | Services.Errors.t
  ]
[@@deriving eq, show { with_path = false }]
