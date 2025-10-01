type t =
  [ Ocaml_protoc_plugin.Result.error
  | Domains.Objects.Errors.t
  | Db.Errors.t
  ]

(** [collect m] enwide error capabilities to [t]. *)
let[@inline] collect m = m |> Result.map_error @@ fun[@inline] e -> (e :> t)
