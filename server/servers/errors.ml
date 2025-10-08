type t =
  [ Ocaml_protoc_plugin.Result.error
  | Domains.Errors.t
  | Db.Errors.t
  ]
