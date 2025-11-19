module Grpc_status = Grpc.Status

module type UC = sig
  val run_usecase
    :  (unit -> ('a, [> Usecases.Errors.t ]) Result.t)
    -> ('a, [> Usecases.Errors.t ]) Result.t

  val get_user_id : unit -> (int64, [> Errors.t ]) result
end

module Grpc (U : UC) = struct
  open Ocaml_protoc_plugin
  open Core

  type ('req, 'res) rpc =
    (module Service.Rpc with type Request.t = 'req and type Response.t = 'res)

  let create_unary_handler' rpc h buf =
    let decode, encode = Service.make_service_functions rpc in
    let open Let.Result in
    U.run_usecase @@ fun () ->
    buf
    |> Reader.create
    |> decode
    |> Errors.widen
    >>= h
    >>| Fun.compose Writer.contents encode
  ;;

  let create_unary_handler (type req) (type res) (rpc : (req, res) rpc) h =
    let module Rpc = (val rpc) in
    let rpc =
      Rpc.(
        ( (module Request : Spec.Message with type t = req)
        , (module Response : Spec.Message with type t = res) ))
    in
    let h s =
      create_unary_handler' rpc h s |> function
      | Ok res ->
        Logs.debug (fun m -> m "gRPC unary handler succeeded");
        Grpc.Status.(v OK), Some res
      | Error err -> Errors.to_status err, None
    in
    Grpc_eio.Server.Service.add_rpc ~name:Rpc.method_name ~rpc:(Unary h)
  ;;

  let create_bistream_handler' rpc h stream f =
    let decode, encode = Service.make_service_functions rpc in
    let exception Break of Errors.t in
    U.run_usecase @@ fun () ->
    Result.map_error ~f:(function
      | Break err -> err
      | exn -> raise_notrace exn)
    @@ Result.try_with
    @@ fun () ->
    Grpc_eio.Seq.iter
      (fun buf ->
         let open Let.Result in
         buf |> Reader.create |> decode |> Errors.widen >>= h |> function
         | Ok response -> response |> encode |> Writer.contents |> f
         | Error e -> raise_notrace (Break e))
      stream;
    Ok ()
  ;;

  let create_bistream_handler (type req) (type res) (rpc : (req, res) rpc) h =
    let module Rpc = (val rpc) in
    let rpc =
      Rpc.(
        ( (module Request : Spec.Message with type t = req)
        , (module Response : Spec.Message with type t = res) ))
    in
    let h stream f =
      create_bistream_handler' rpc h stream f |> function
      | Ok _res -> Grpc.Status.(v OK)
      | Error err -> Errors.to_status err
    in
    Grpc_eio.Server.Service.(
      add_rpc ~name:Rpc.method_name ~rpc:(Bidirectional_streaming h))
  ;;
end
