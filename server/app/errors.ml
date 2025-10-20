type grpc = [ `Not_ok of Grpc.Status.code ] [@@deriving show { with_path = false }]

type t =
  [ Ocaml_protoc_plugin.Result.error
  | Usecases.Errors.t
  | Oenv.Errors.t
  | grpc
  ]
[@@deriving show { with_path = false }]
