open Core

open struct
  module Bwd = struct
    module File = Protos.Oresai_services_user
    module Service = File.Oresai.Services.UserService
    module User = Protos.Oresai_objects_user.Oresai.Objects.User
  end

  let get_user_me (m : (module Utils.UC)) =
    let module Rpc = Bwd.Service.GetUserMe in
    let module M = (val m) in
    let module G = Utils.Grpc (M) in
    G.create_unary_handler (module Rpc) @@ fun () ->
    let open Let.Result in
    let* user_id = M.get_user_id () in
    let* user = Usecases.Get_user_by_id.run ~user_id in
    return
    @@ Rpc.Response.make
         ~user:
           (Bwd.User.make
              ~id:(Domains.Objects.User.id user)
              ~name:(Domains.Objects.User.name user)
              ~email:(Domains.Objects.User.email user)
              ~display_name:(Domains.Objects.User.display_name user)
              ~bio:(Domains.Objects.User.bio user)
              ?avatar_url:(Domains.Objects.User.avatar_url user)
              ~links:(Domains.Objects.User.links user)
              ())
         ()
  ;;

  let update_user_me (m : (module Utils.UC)) =
    let module Rpc = Bwd.Service.UpdateUserMe in
    let module M = (val m) in
    let module G = Utils.Grpc (M) in
    G.create_unary_handler (module Rpc)
    @@ fun { name; display_name; bio; avatar_url; links } ->
    let open Let.Result in
    let* user_id = M.get_user_id () in
    let* user =
      Usecases.User_update_me.run ~user_id ?name ?display_name ?bio ?avatar_url ~links ()
    in
    return
    @@ Rpc.Response.make
         ~id:(Domains.Objects.User.id user)
         ~name:(Domains.Objects.User.name user)
         ~email:(Domains.Objects.User.email user)
         ~display_name:(Domains.Objects.User.display_name user)
         ~bio:(Domains.Objects.User.bio user)
         ?avatar_url:(Domains.Objects.User.avatar_url user)
         ~links:(Domains.Objects.User.links user)
         ()
  ;;

  let service m =
    Grpc_eio.Server.Service.(v () |> get_user_me m |> update_user_me m |> handle_request)
  ;;
end

let register m =
  Grpc_eio.Server.add_service ~name:Bwd.Service.package_service_name ~service:(service m)
;;
