open Core

open struct
  module Bwd = struct
    module File = Protos.Oresai_services_auth
    module Service = File.Oresai.Services.AuthService
    module User = Protos.Oresai_objects_user.Oresai.Objects.User
  end

  let register (m : (module Utils.UC)) =
    let module Rpc = Bwd.Service.Register in
    let module G = Utils.Grpc ((val m)) in
    G.create_unary_handler (module Rpc)
    @@ fun { name; email; password; display_name; bio; avatar_url; links } ->
    let open Let.Result in
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
      >>| Domains.Objects.User.Id.to_
    in
    return @@ Rpc.Response.make ~user_id ()
  ;;

  let login ~env (m : (module Utils.UC)) =
    let clock = Eio.Stdenv.clock env in
    let module Rpc = Bwd.Service.Login in
    let module G = Utils.Grpc ((val m)) in
    G.create_unary_handler (module Rpc) @@ fun { email; password } ->
    let open Let.Result in
    let* email = Domains.Objects.User.Email.from email in
    let* user = Usecases.Get_user_by_email.run ~email ~password in
    let* access_token = Usecases.User_create_auth_token.run ~clock ~user in
    return @@ Rpc.Response.make ~access_token ()
  ;;

  let service ~env m =
    Grpc_eio.Server.Service.(v () |> register m |> login ~env m |> handle_request)
  ;;
end

let register ~env m =
  Grpc_eio.Server.add_service
    ~name:Bwd.Service.package_service_name
    ~service:(service ~env m)
;;
