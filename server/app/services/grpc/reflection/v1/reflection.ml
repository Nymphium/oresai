open Core

open struct
  module Bwd = struct
    module File = Protos.Grpc_reflection_v1_reflection
    module Proto = File.Grpc.Reflection.V1
    module Service = Proto.ServerReflection
  end

  let server_reflection_info =
    let module Op = Ocaml_protoc_plugin in
    let module Rpc = Bwd.Service.ServerReflectionInfo in
    Utils.Grpc.create_bistream_handler (module Rpc) @@ fun request ->
    match request.message_request with
    | `File_containing_symbol sym ->
      let s = Protos.fd_of_service sym in
      (match s with
       | Some fd ->
         let res =
           `File_descriptor_response
             (Bwd.Proto.FileDescriptorResponse.make
                ~file_descriptor_proto:[ fd |> Bytes.of_string ]
                ())
         in
         Result.return
         @@ Rpc.Response.make ~original_request:request ~message_response:res ()
       | _ -> Error (`Not_ok Utils.Grpc.Status.Not_found))
    | `File_by_filename fname ->
      let s = Protos.fd_of_file fname in
      (match s with
       | Some fd ->
         let res =
           `File_descriptor_response
             (Bwd.Proto.FileDescriptorResponse.make
                ~file_descriptor_proto:[ fd |> Bytes.of_string ]
                ())
         in
         Result.return
         @@ Rpc.Response.make ~original_request:request ~message_response:res ()
       | _ -> Error (`Not_ok Utils.Grpc.Status.Not_found))
    | `List_services _ ->
      let res =
        `List_services_response
          (Bwd.Proto.ListServiceResponse.make
             ~service:
               (Protos.service_list
                |> List.map ~f:(fun name -> Bwd.Proto.ServiceResponse.make () ~name))
             ())
      in
      Result.return
      @@ Rpc.Response.make ~original_request:request ~message_response:res ()
    | _ -> Error (`Not_ok Utils.Grpc.Status.Unimplemented)
  ;;

  let service = Grpc_eio.Server.Service.(v () |> server_reflection_info |> handle_request)
end

let register = Grpc_eio.Server.add_service ~name:Bwd.Service.package_service_name ~service

module Metainfo = Bwd.File.Metainfo
