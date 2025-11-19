open Core

type error = [ `Invalid_user_id ] [@@deriving eq, show { with_path = false }]

let run ~user_id =
  let open Let.Result in
  let* user = Domains.Repositories.(Locator.run @@ User.FindById { user_id }) in
  Result.of_option ~error:`Invalid_user_id user
;;
