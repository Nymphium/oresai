open Core

open struct
  module Bwd = struct
    module File = Protos.Oresai_services_auth
    module Service = File.Oresai.Services.AuthService
    module User = Protos.Oresai_objects_user.Oresai.Objects.User
  end

  let register =
    let module Op = Ocaml_protoc_plugin in
    let module Rpc = Bwd.Service.Register in
    Utils.Grpc.create_unary_handler (module Rpc)
    @@ fun { name; email; password; display_name; bio; avatar_url; links } ->
    let open Let.Result in
    Utils.Handler.v @@ fun () ->
    let* user_id =
      Usecases.Register_user.run
        ~name
        ~email
        ~password
        ~display_name
        ~bio
        ?avatar_url
        ~links
        ()
    in
    return @@ Rpc.Response.make ~user_id ()
  ;;

  let login env =
    let clock = Eio.Stdenv.clock env in
    let module Op = Ocaml_protoc_plugin in
    let module Rpc = Bwd.Service.Login in
    Utils.Grpc.create_unary_handler (module Rpc) @@ fun { email; password } ->
    let open Let.Result in
    Utils.Handler.v @@ fun () ->
    let* email = Domains.Objects.User.Email.from email in
    let* user = Usecases.Get_user_by_email.run ~email ~password in
    let* access_token = Usecases.User_create_auth_token.run ~user ~clock in
    return @@ Rpc.Response.make ~access_token ()
  ;;

  let service env =
    Grpc_eio.Server.Service.(v () |> register |> login env |> handle_request)
  ;;
end

let register env =
  Grpc_eio.Server.add_service
    ~name:Bwd.Service.package_service_name
    ~service:(service env)
;;

module Metainfo = Bwd.File.Metainfo
