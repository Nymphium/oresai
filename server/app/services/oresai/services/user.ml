open Core

open struct
  module Bwd = struct
    module Service = Protos.Oresai_services_user.Oresai.Services.UserService
    module User = Protos.Oresai_objects_user.Oresai.Objects.User
  end

  let get_user_me =
    let module Op = Ocaml_protoc_plugin in
    let module Rpc = Bwd.Service.GetUserMe in
    Utils.Grpc.create_unary_handler
      (module Rpc)
      ~h:(fun ~decode:_ ~encode _ ->
        let open Let.Result in
        let* user_id = Utils.Grpc.get_user_id () in
        let* user = Usecases.Get_user_by_id.run ~user_id in
        let reply =
          Rpc.Response.make
            ~user:
              (Bwd.User.make
                 ~id:(Domains.Objects.User.id user)
                 ~name:(Domains.Objects.User.name user)
                 ~email:(Domains.Objects.User.email user)
                 ~display_name:(Domains.Objects.User.display_name user)
                 ~bio:(Domains.Objects.User.bio user)
                 ~avatar_url:(Domains.Objects.User.avatar_url user)
                 ~links:(Domains.Objects.User.links user)
                 ())
            ()
        in
        return @@ (encode reply |> Op.Writer.contents))
  ;;

  (* let update_user_me = *)
  (*   let module Op = Ocaml_protoc_plugin in *)
  (*   let module Rpc = Bwd.Service.UpdateUserMe in *)
  (*   Utils.Grpc.create_unary_handler *)
  (*     (module Rpc) *)
  (*     ~h:(fun ~decode ~encode buf -> *)
  (*       let open Let.Result in *)
  (*       let* { name; display_name; bio; avatar_url; links; } = Op.Reader.create buf |> decode in *)
  (*       let* user = Usecases.Get_user_by_id.run ~user_id in *)
  (*       let reply = *)
  (*         Rpc.Response.make *)
  (*           ~user: *)
  (*             (Bwd.User.make *)
  (*                ~id:(Domains.Objects.User.id user) *)
  (*                ~name:(Domains.Objects.User.name user) *)
  (*                ~email:(Domains.Objects.User.email user) *)
  (*                ~display_name:(Domains.Objects.User.display_name user) *)
  (*                ~bio:(Domains.Objects.User.bio user) *)
  (*                ~avatar_url:(Domains.Objects.User.avatar_url user) *)
  (*                ~links:(Domains.Objects.User.links user) *)
  (*                ()) *)
  (*           () *)
  (*       in *)
  (*       return @@ (encode reply |> Op.Writer.contents)) *)
  (* ;; *)

  let service = Grpc_eio.Server.Service.(v () |> get_user_me |> handle_request)
end

let register =
  Grpc_eio.Server.add_service
    ~name:
      [%string
        {|$(Option.value ~default:""
    (Bwd.Service.GetUserMe.package_name)).$(Bwd.Service.GetUserMe.service_name)|}]
    ~service
;;
