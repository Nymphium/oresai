open Core

open struct
  let auth ~jwt_secret ~clock th =
    try th () with
    | effect Services.Auth.Token.Create_with_user_id { user_id }, k ->
      Effect.Deep.continue k @@ Jwt.create_with_user_id ~secret:jwt_secret ~clock ~user_id
    | effect Services.Auth.Token.Confirm { token }, k ->
      Effect.Deep.continue k
      @@
      let open Let.Result in
      let* payload = Jwt.verify_token ~secret:jwt_secret ~clock ~token in
      let* () = Jwt.check_exprity ~clock payload in
      Jwt.user_id_of_payload payload
  ;;
end

let v ~jwt_secret ~env th =
  let clock = Eio.Stdenv.clock env in
  auth ~jwt_secret ~clock th
;;
