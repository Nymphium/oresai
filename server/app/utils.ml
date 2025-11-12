open Core

let widen_errors = Result.map_error ~f:(fun err -> (err :> Errors.t))

module Grpc = struct
  open Ocaml_protoc_plugin
  open Core
  module Status = Grpc.Status

  type ('req, 'res) rpc =
    (module Service.Rpc with type Request.t = 'req and type Response.t = 'res)

  let create_unary_handler' rpc h buf =
    let decode, encode = Service.make_service_functions rpc in
    let conn = Eio.Fiber.get Context.conn |> Option.value_exn in
    Db.Handler.v conn @@ fun () ->
    Reader.create buf
    |> decode
    |> widen_errors
    |> Result.bind ~f:h
    |> Result.map ~f:(fun reply -> encode reply |> Writer.contents)
  ;;

  let create_unary_handler (type req) (type res) (rpc : (req, res) rpc) h =
    let module Rpc = (val rpc) in
    let rpc =
      Rpc.(
        ( (module Request : Spec.Message with type t = req)
        , (module Response : Spec.Message with type t = res) ))
    in
    let h s =
      Result.try_with (fun () -> s |> create_unary_handler' rpc h)
      |> Result.map_error ~f:(fun exn -> `Exn exn)
      |> Result.join
      |> function
      | Ok res -> Grpc.Status.(v OK), Some res
      | Error (`Not_ok code') -> Grpc.Status.(v code'), None
      | Error err ->
        Logs.err (fun m ->
          m "gRPC error" ~tags:Logs.Tag.(empty |> add (def "error" Errors.pp) err));
        Grpc.Status.(v Internal), None
    in
    Grpc_eio.Server.Service.(add_rpc ~name:Rpc.method_name ~rpc:(Unary h))
  ;;

  let create_bistream_handler' rpc h stream f =
    let decode, encode = Service.make_service_functions rpc in
    let conn = Eio.Fiber.get Context.conn |> Option.value_exn in
    let exception Break of Errors.t in
    Db.Handler.v conn @@ fun () ->
    Result.map_error ~f:(function
      | Break err -> err
      | exn -> `Exn exn)
    @@ Result.try_with
    @@ fun () ->
    Grpc_eio.Seq.iter
      (fun buf ->
         let open Let.Result in
         ( function
           | Ok v -> v
           | Error e -> raise_notrace (Break e) )
         @@
         let* msg = Reader.create buf |> decode |> widen_errors in
         let* reply = h msg in
         return (reply |> encode |> Writer.contents |> f))
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
      Result.try_with (fun () -> create_bistream_handler' rpc h stream f)
      |> Result.map_error ~f:(fun exn -> `Exn exn)
      |> Result.join
      |> function
      | Ok _res -> Grpc.Status.(v OK)
      | Error (`Not_ok code') ->
        Logs.err (fun m ->
          m
            "gRPC error"
            ~tags:Logs.Tag.(empty |> add (def "code" Grpc.Status.pp_code) code'));
        Grpc.Status.(v code')
      | Error err ->
        Logs.err (fun m ->
          m "gRPC error" ~tags:Logs.Tag.(empty |> add (def "error" Errors.pp) err));
        Grpc.Status.(v Internal)
    in
    Grpc_eio.Server.Service.(
      add_rpc ~name:Rpc.method_name ~rpc:(Bidirectional_streaming h))
  ;;

  (** [get_user_id] retrieves the user_id from the evaluation context.
    The id is not a real id, so it needs to be verified in the database. *)
  let get_user_id () =
    Eio.Fiber.get Context.user_id
    |> Option.map ~f:Domains.Objects.User.Id.to_
    |> Result.of_option ~error:(`Not_ok Status.Unauthenticated)
  ;;

  let ensure_logged_in () = get_user_id () |> Result.map ~f:(Fn.const ())
end

module Handler = struct
  open struct
    open Usecases.Locator

    let system : type a. a System.action -> a = function
      | System.Ping -> Db.System.ping ()
    ;;

    let users : type a. a Users.action -> a =
      let open Users in
      function
      | Create { name; email; display_name; bio; avatar_url; password; links } ->
        Db.Users.create
          ~name
          ~email
          ~display_name
          ~bio
          ?avatar_url
          ~hashed_password:password
          ~links
          ()
      | CheckPassword { user_id; password } -> Db.Users.check_password user_id password
      | FindByEmail { email } -> Db.Users.find_by_email email
      | FindById { user_id } -> Db.Users.find_by_id user_id
      | Update { user_id; name; display_name; bio; avatar_url; links } ->
        Db.Users.update user_id ?name ?display_name ?bio ?avatar_url ?links ()
    ;;

    let memos : type a. a Memos.action -> a =
      let open Memos in
      function
      | Create { content; user_id; tag_ids; state } ->
        Db.Memos.create ~content ~user_id ~tag_ids ~state
      | ListByUser { user_id } -> Db.Memos.list_by_user_id user_id
    ;;

    let articles : type a. a Articles.action -> a =
      let open Articles in
      function
      | Create { title; content; user_id; tag_ids; state } ->
        Db.Articles.create ~title ~content ~user_id ~tag_ids ~state
      | ListByUser { user_id } -> Db.Articles.list_by_user_id user_id
    ;;

    let handle_uc th () =
      Usecases.Locator.(
        handle (function
          | Users.W uc -> users uc
          | Memos.W uc -> memos uc
          | Articles.W uc -> articles uc
          | System.W uc -> system uc
          | _ -> failwith "unhandled repo"))
        th
    ;;
  end

  let v th =
    let conn = Eio.Fiber.get Context.conn |> Option.value_exn in
    Db.Handler.v conn @@ handle_uc th
  ;;
end
