open Core

type error =
  [ `Invalid_password
  | `Missing_email
  ]
[@@deriving eq, show { with_path = false }]

let run ~email ~password =
  let open Let.Result in
  let email = Domains.Objects.User.Email.to_ email in
  let* user =
    Domains.Repositories.(Locator.run User.(FindByEmail { email }))
    >>= Result.of_option ~error:`Missing_email
  in
  let* ok =
    Domains.Repositories.(
      Locator.run @@ User.(CheckPassword { user_id = user.id; password }))
  in
  if not ok then Error `Invalid_password else Ok user
;;
