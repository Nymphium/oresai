open Core

open struct
  module Bwd = struct
    module Service = Protos.Oresai_services_auth.Oresai.Services.AuthService
    module User = Protos.Oresai_objects_user.Oresai.Objects.User
  end

  let register =
    let module Op = Ocaml_protoc_plugin in
    let module Rpc = Bwd.Service.Register in
    Utils.Grpc.create_unary_handler
      (module Rpc)
      ~h:(fun ~decode ~encode buf ->
        let open Let.Result in
        let* user_id =
          let* { name; email; password; display_name; bio; avatar_url; links } =
            Op.Reader.create buf |> decode
          in
          Usecases.Register_user.run
            ~name
            ~email
            ~password
            ~display_name
            ~bio
            ~avatar_url
            ~links
        in
        let reply = Rpc.Response.make ~user_id () in
        return @@ (encode reply |> Op.Writer.contents))
  ;;

  let login env =
    let clock = Eio.Stdenv.clock env in
    let module Op = Ocaml_protoc_plugin in
    let module Rpc = Bwd.Service.Login in
    Utils.Grpc.create_unary_handler
      (module Rpc)
      ~h:(fun ~decode ~encode buf ->
        let open Let.Result in
        let conn = Eio.Fiber.get Context.conn |> Option.value_exn in
        Db.Handler.v conn @@ fun () ->
        let* { email; password } = Op.Reader.create buf |> decode in
        let* user = Usecases.Get_user_by_email.run ~email ~password in
        let* jwt = Usecases.User_create_auth_token.run ~user ~clock in
        let reply = Rpc.Response.make ~access_token:jwt () in
        return @@ (encode reply |> Op.Writer.contents))
  ;;

  let service env =
    Grpc_eio.Server.Service.(v () |> register |> login env |> handle_request)
  ;;
end

let register env =
  Grpc_eio.Server.add_service
    ~name:
      [%string
        {|$(Option.value ~default:""
    (Bwd.Service.Login.package_name)).$(Bwd.Service.Login.service_name)|}]
    ~service:(service env)
;;
