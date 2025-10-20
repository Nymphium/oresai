open Core

type error = [ `Invalid_user_id of int64 ] [@@deriving eq, show { with_path = false }]

let run ~user_id =
  let open Let.Result in
  let* user = Db.Users.find_by_id user_id in
  Result.of_option ~error:(`Invalid_user_id user_id) user
;;
