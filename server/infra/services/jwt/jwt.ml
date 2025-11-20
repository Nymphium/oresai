open Core

open struct
  let algo = Jwto.HS256

  module Key = struct
    let expirity = "exp"
    let user_id = "sub"
  end
end

let create_with_user_id ~user_id ~secret ~clock =
  let open Let.Result in
  Jwto.encode
    algo
    secret
    [ Key.user_id, Int64.to_string user_id
    ; Key.expirity, Float.to_string @@ Eio.Time.now clock
    ]
  >>? Fun.const (`EncryptionError "jwt")
;;

let check_exprity ~clock payload =
  let open Let.Result in
  let* expirity =
    Jwto.get_claim Key.expirity payload
    |> of_option ~error:(`DecryptionError "exp claim missing")
    >>| Float.of_string_opt
    >>= of_option ~error:(`DecryptionError "invalid exp claim")
  in
  if Float.(Eio.Time.now clock > expirity)
  then Error (`DecryptionError "Expired signature")
  else Ok ()
;;

let verify_token ~token ~secret ~clock =
  let open Let.Result in
  let* payload =
    Jwto.decode_and_verify secret token
    >>? (fun s -> `DecryptionError s)
    >>| Jwto.get_payload
  in
  let* () = check_exprity payload ~clock in
  return payload
;;

let user_id_of_payload payload =
  let open Let.Option in
  Jwto.get_claim Key.user_id payload
  >>= Int64.of_string_opt
  |> Result.of_option ~error:(`DecryptionError "sub claim missing")
;;
