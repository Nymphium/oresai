open Core

open struct
  let algo = Jwto.HS256
end

let from ~now ~user_id =
  let open Jwto in
  let header = make_header algo in
  let uns =
    make_unsigned_token
      header
      [ "sub", Int64.to_string user_id; "exp", Float.to_string now ]
  in
  make_signed_token "" uns |> Result.map_error ~f:(Fun.const (`EncryptionError "jwt"))
;;

let to_ t =
  let buf = Buffer.create 16 in
  let fmt = Format.formatter_of_buffer buf in
  let () = Format.fprintf fmt "%a" Jwto.pp t in
  Buffer.contents buf
;;

let get_user_id token =
  let open Let.Result in
  let* t =
    Jwto.decode_and_verify token "" |> Result.map_error ~f:(fun s -> `DecryptionError s)
  in
  let payload = Jwto.get_payload t in
  Result.of_option ~error:(`DecryptionError "token")
  @@
  let open Let.Option in
  let* sub = List.Assoc.find ~equal:String.equal payload "sub" in
  Int64.of_string_opt sub
;;
