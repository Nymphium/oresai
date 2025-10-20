open Core

open struct
  module Bwd = struct
    module Proto = Protos.Grpc_health_v1_health.Grpc.Health.V1
    module Service = Proto.Health
  end

  let check =
    let module Op = Ocaml_protoc_plugin in
    let module Rpc = Bwd.Service.Check in
    Utils.Grpc.create_unary_handler
      (module Rpc)
      ~h:(fun ~decode ~encode buf ->
        let open Let.Result in
        let* request = Op.Reader.create buf |> decode in
        Logs.info (fun m -> m "Health check requested %s" request);
        let status = Bwd.Proto.HealthCheckResponse.ServingStatus.SERVING in
        let reply = Rpc.Response.make ~status () in
        return @@ (encode reply |> Op.Writer.contents))
  ;;

  let service = Grpc_eio.Server.Service.(v () |> check |> handle_request)
end

let register =
  Grpc_eio.Server.add_service
    ~name:
      [%string
        {|$(Option.value ~default:""
    (Bwd.Service.Check.package_name)).$(Bwd.Service.Check.service_name)|}]
    ~service
;;
