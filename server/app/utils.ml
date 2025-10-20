open Core

let widen_errors = Result.map_error ~f:(fun err -> (err :> Errors.t))

module Grpc = struct
  open Ocaml_protoc_plugin
  open Core
  module Status = Grpc.Status

  type ('req, 'res) rpc =
    (module Service.Rpc with type Request.t = 'req and type Response.t = 'res)

  let create_handler rpc h buf =
    let decode, encode = Service.make_service_functions rpc in
    let decode s = s |> decode |> widen_errors in
    let conn = Eio.Fiber.get Context.conn |> Option.value_exn in
    Db.Handler.v conn @@ fun () -> h ~decode ~encode buf
  ;;

  let create_unary_handler (type req) (type res) (rpc : (req, res) rpc) ~h =
    let module Rpc = (val rpc) in
    let rpc =
      Rpc.(
        ( (module Request : Spec.Message with type t = req)
        , (module Response : Spec.Message with type t = res) ))
    in
    let h s =
      Result.try_with (fun () -> s |> create_handler rpc h)
      |> Result.map_error ~f:(fun exn -> `Exn exn)
      |> Result.join
      |> function
      | Ok res -> Grpc.Status.(v OK), Some res
      | Error (`Not_ok code') -> Grpc.Status.(v code'), None
      | Error err ->
        Logs.err (fun m ->
          m "gRPC error" ~tags:Logs.Tag.(empty |> add (def "error" Errors.pp) err));
        Grpc.Status.(v Internal), None
    in
    Grpc_eio.Server.Service.(add_rpc ~name:Rpc.method_name ~rpc:(Unary h))
  ;;

  (** [get_user_id] retrieves the user_id from the evaluation context.
    The id is not a real id, so it needs to be verified in the database. *)
  let get_user_id () =
    Eio.Fiber.get Context.user_id
    |> Option.map ~f:Domains.Objects.User.Id.to_
    |> Result.of_option ~error:(`Not_ok Status.Unauthenticated)
  ;;

  let ensure_logged_in () = get_user_id () |> Result.map ~f:(Fn.const ())
end
