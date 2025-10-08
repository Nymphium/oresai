open Core

let () = Mirage_crypto_rng_unix.use_default ()

open struct
  let hash_alg = "scrypt"
  let hash_n = 32768
  let hash_r = 8
  let hash_p = 1
  let hash_dk_len = 32l
end

include (
struct
  let prefix = [%string {|$$$(hash_alg)$$n=%d$(hash_n),r=%d$(hash_r),p=%d$(hash_p)$$|}]

  type bwd = string [@@deriving eq, show]
  type t = bwd [@@deriving eq, show]

  let to_ = Fun.id
  let validate _ = false

  let from password =
    let open Let.Result in
    let salt = Mirage_crypto_rng.generate 16 in
    let* hash =
      Result.(
        try_with (fun () ->
          Scrypt.scrypt ~password ~salt ~n:hash_n ~r:hash_r ~p:hash_p ~dk_len:hash_dk_len)
        |> map_error ~f:(Fun.const (`EncryptionError "scrypt")))
    in
    let salt_b64 = Base64.encode_string ~pad:true salt in
    let dk_b64 = Base64.encode_string ~pad:true hash in
    return @@ [%string {|$(prefix)$(salt_b64)$$$(dk_b64)|}]
  ;;

  let unsafe_from =
    Fn.compose Result.(Fn.compose ok_or_failwith (map_error ~f:Errors.show)) from
  ;;
end :
  Morph.SealedHom with type bwd = string)

(** [verify] checks whether the given [plain] matches the plain text of
    [hashed]. *)
let verify ~plain ~hashed =
  match String.split ~on:'$' @@ to_ hashed with
  | [ ""; alg; _params; salt_b64; dk_b64 ] when String.equal alg hash_alg ->
    let open Let.Result in
    let* salt =
      Base64.decode salt_b64 |> map_error ~f:(fun (`Msg msg) -> `DecryptionError msg)
    in
    let* dk =
      Base64.decode dk_b64 |> map_error ~f:(fun (`Msg msg) -> `DecryptionError msg)
    in
    let* hash =
      try_with (fun () ->
        Scrypt.scrypt
          ~password:plain
          ~salt
          ~n:hash_n
          ~r:hash_r
          ~p:hash_p
          ~dk_len:hash_dk_len)
      |> map_error ~f:(Fun.const (`DecryptionError "scrypt"))
    in
    return @@ String.equal hash dk
  | "" :: otheralg :: _ ->
    Result.Error (`DecryptionError [%string "hashed_string: unknown alg $(otheralg)"])
  | _ -> Result.Error (`DecryptionError "invalid hashed string format")
;;

let%test _ =
  let plain = "password" in
  let hashed = Result.(from plain |> map_error ~f:Errors.show |> ok_or_failwith) in
  verify ~plain ~hashed |> Result.map_error ~f:Errors.show |> Result.ok_or_failwith
;;
