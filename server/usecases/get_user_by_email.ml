open Core

type error = [ `Invalid_password ] [@@deriving eq, show { with_path = false }]

let run ~email ~password =
  let open Let.Result in
  let* user = Db.Users.find_by_email email in
  let user = Option.value_exn user in
  let* ok = Db.Users.check_password user.id password in
  if not ok then Error `Invalid_password else Ok user
;;
