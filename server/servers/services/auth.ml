open struct
  module Bwd = struct
    module Service = Protos.Oresai_services_auth.Oresai.Services.AuthService
    module User = Protos.Oresai_objects_user.Oresai.Objects.User
  end

  let register =
    let module Op = Ocaml_protoc_plugin in
    let module Rpc = Bwd.Service.Register in
    Grpc.create_unary_handler
      (module Rpc)
      ~h:(fun ~decode ~encode buf ->
        let open Let.Result in
        let* user_id =
          let* request = Op.Reader.create buf |> decode |> Errors.collect in
          let* name = Domains.Objects.User.Name.from request.name |> Errors.collect in
          let* email = Domains.Objects.User.Email.from request.email |> Errors.collect in
          Db.Users.create ~name ~email >>| Domains.Objects.User.id
        in
        let reply = Rpc.Response.make ~user_id () in
        return @@ (encode reply |> Op.Writer.contents))
  ;;

  let service = Grpc_eio.Server.Service.(v () |> register |> handle_request)
end

let register =
  Grpc_eio.Server.add_service
    ~name:
      [%string
        {|$(Option.value ~default:""
    (Bwd.Service.Login.package_name))/$(Bwd.Service.Login.service_name)|}]
    ~service
;;
