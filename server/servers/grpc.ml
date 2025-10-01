open Ocaml_protoc_plugin
open Core

type ('req, 'res) rpc =
  (module Service.Rpc with type Request.t = 'req and type Response.t = 'res)

let create_handler rpc h =
  let decode, encode = Service.make_service_functions rpc in
  h ~decode ~encode
;;

let create_unary_handler (type req) (type res) (rpc : (req, res) rpc) ~h =
  let module Rpc = (val rpc) in
  let rpc =
    Rpc.(
      ( (module Request : Spec.Message with type t = req)
      , (module Response : Spec.Message with type t = res) ))
  in
  let h =
    Fn.(flip compose) (create_handler rpc h)
    @@ function
    | Error _ -> failwith "error"
    | Ok res -> Grpc__Status.(v OK), Some res
  in
  Grpc_eio.Server.Service.(add_rpc ~name:Rpc.name ~rpc:(Unary h))
;;
