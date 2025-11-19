open Core

let run ~clock token =
  let open Let.Result in
  let* t =
    Jwto.decode_and_verify "" token |> Result.map_error ~f:(fun s -> `DecryptionError s)
  in
  let payload = Jwto.get_payload t in
  let* () =
    let open Let.Result in
    let* exp_str =
      Result.of_option ~error:(`DecryptionError "exp claim missing")
      @@ List.Assoc.find ~equal:String.equal payload "exp"
    in
    let* exp =
      Result.of_option ~error:(`DecryptionError "invalid exp claim")
      @@ Float.of_string_opt exp_str
    in
    if Float.compare (Eio.Time.now clock) exp > 0
    then Error (`DecryptionError "Expired signature")
    else Ok ()
  in
  Result.of_option ~error:(`DecryptionError "sub claim missing")
  @@
  let open Let.Option in
  let* sub = List.Assoc.find ~equal:String.equal payload "sub" in
  Int64.of_string_opt sub
;;
