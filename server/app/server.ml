open Core

let[@inline] services env =
  Grpc_eio.Server.v ()
  |> Services.Grpc.Reflection.V1.Reflection.register
  |> Services.Grpc.Health.V1.Health.register
  |> Services.Oresai.Services.Auth.register env
  |> Services.Oresai.Services.User.register
;;

let[@inline] icept ~env stream reqd close =
  let open Icept in
  New.(v stream reqd (Request_logger.register +> Auth.register ~env +> close))
;;

let connection_handler ~sw ~env server =
  let icept = icept ~env in
  let error_handler _client_address ?request:_ _error start_response =
    Logs.err (fun m -> m "Error handling request");
    let response_body = start_response H2.Headers.empty in
    H2.Body.Writer.write_string response_body "";
    H2.Body.Writer.close response_body
  in
  let request_handler client_address reqd =
    Eio.Fiber.fork ~sw @@ fun () ->
    icept client_address reqd @@ fun _stream reqd ->
    Grpc_eio.Server.handle_request server reqd
  in
  let config =
    H2.Config.
      { default with
        enable_server_push = false
      ; request_body_buffer_size = 16 * 1024
      ; response_body_buffer_size = 16 * 1024
      ; max_concurrent_streams = Int32.max_value
      ; initial_window_size = Int32.of_int_exn @@ (1024 * 1024)
      }
  in
  fun socket addr ->
    H2_eio.Server.create_connection_handler
      ~config
      ~sw
      ~request_handler
      ~error_handler
      addr
      socket
;;

let serve ~env ~sw ~port =
  let net = Eio.Stdenv.net env in
  let addr = `Tcp (Eio.Net.Ipaddr.V4.loopback, port) in
  let handler = connection_handler ~env ~sw (services env) in
  let server_socket = Eio.Net.listen net ~sw ~reuse_addr:true ~backlog:128 addr in
  let rec listen () =
    let () = Eio.Net.accept_fork ~sw server_socket ~on_error:raise_notrace handler in
    listen ()
  in
  listen ()
;;

(** TODO: exp retry *)
let chehealth ~env:_ ~sw:_ = Utils.Handler.v @@ fun () -> Usecases.System_ping.run ()
