type t =
  [ Domains.Errors.t
  | Get_user_by_email.error
  | Get_user_by_id.error
  | User_create_auth_token.error
  ]
[@@deriving eq, show { with_path = false }]
