open Core

let run token =
  let open Let.Result in
  let* t =
    Jwto.decode_and_verify "" token |> Result.map_error ~f:(fun s -> `DecryptionError s)
  in
  let payload = Jwto.get_payload t in
  Result.of_option ~error:(`DecryptionError "token")
  @@
  let open Let.Option in
  let* sub = List.Assoc.find ~equal:String.equal payload "sub" in
  Int64.of_string_opt sub
;;
