type t =
  [ Usecases.Errors.t
  | Ocaml_protoc_plugin.Result.error
  | `Not_ok of Grpc.Status.code
  ]
[@@deriving show { with_path = false }]

let widen = Core.Result.map_error ~f:(fun err -> (err :> t))

let to_status = function
  | `Not_ok code' -> Grpc.Status.(v code')
  | #Ocaml_protoc_plugin.Result.error as _err ->
    (* Logs.err (fun m -> m "gRPC error" ~tags:Logs.Tag.(empty |> add (def "error" pp) err)); *)
    Grpc.Status.(v Internal)
  | #Usecases.Errors.t as _err -> Grpc.Status.(v Internal)
;;
