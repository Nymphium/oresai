open Core

open struct
  module Bwd = struct
    module File = Protos.Grpc_health_v1_health
    module Proto = File.Grpc.Health.V1
    module Service = Proto.Health
  end

  let check =
    let module Op = Ocaml_protoc_plugin in
    let module Rpc = Bwd.Service.Check in
    Utils.Grpc.create_unary_handler (module Rpc) @@ fun request ->
    Logs.info (fun m ->
      m
        ~tags:Logs.Tag.(empty |> add (def "request" Format.pp_print_string) request)
        "Health check requested %s"
        request);
    let open Let.Result in
    Utils.Handler.v @@ fun () ->
    let pong = Usecases.System_ping.run () in
    match pong with
    | Ok () ->
      let status = Bwd.Proto.HealthCheckResponse.ServingStatus.SERVING in
      return @@ Rpc.Response.make ~status ()
    | Error _ ->
      let status = Bwd.Proto.HealthCheckResponse.ServingStatus.NOT_SERVING in
      return @@ Rpc.Response.make ~status ()
  ;;

  let service = Grpc_eio.Server.Service.(v () |> check |> handle_request)
end

let register = Grpc_eio.Server.add_service ~name:Bwd.Service.package_service_name ~service

module Metainfo = Bwd.File.Metainfo
