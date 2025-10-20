open Core

let[@inline] services env =
  Grpc_eio.Server.v ()
  (* |> Services.Grpc.Reflection.V1.Reflection.register *)
  |> Services.Grpc.Health.V1.Health.register
  |> Services.Oresai.Services.Auth.register env
  |> Services.Oresai.Services.User.register
;;

let[@inline] icept stream reqd close =
  let open Icept in
  New.(v stream reqd (Request_logger.register +> Auth.register +> close))
;;

let connection_handler server sw =
  let error_handler _client_address ?request:_ _error start_response =
    Logs.err (fun m -> m "Error handling request");
    let response_body = start_response H2.Headers.empty in
    H2.Body.Writer.write_string
      response_body
      "There was an error handling your request.\n";
    H2.Body.Writer.close response_body
  in
  let request_handler client_address reqd =
    Eio.Fiber.fork ~sw @@ fun () ->
    icept client_address reqd @@ fun _stream reqd ->
    Grpc_eio.Server.handle_request server reqd
  in
  fun socket addr ->
    H2_eio.Server.create_connection_handler
      ~sw
      ~request_handler
      ~error_handler
      addr
      socket
;;

let serve ~env ~sw ~port =
  let net = Eio.Stdenv.net env in
  let addr = `Tcp (Eio.Net.Ipaddr.V4.loopback, port) in
  let handler = connection_handler (services env) sw in
  let server_socket = Eio.Net.listen net ~sw ~reuse_addr:true ~backlog:10 addr in
  let rec listen () =
    let () = Eio.Net.accept_fork ~sw server_socket ~on_error:raise_notrace handler in
    listen ()
  in
  listen ()
;;
