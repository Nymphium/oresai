open Core

let[@inline] services ~env (m : (module Grpc'.Utils.UC)) =
  Grpc_eio.Server.v ()
  |> Grpc'.Services.Grpc.Reflection.V1.Reflection.register m
  |> Grpc'.Services.Grpc.Health.V1.Health.register m
  |> Grpc'.Services.Oresai.Services.Auth.register ~env m
  |> Grpc'.Services.Oresai.Services.User.register m
;;

let[@inline] icept ~env stream reqd close =
  let open Grpc'.Icept in
  New.(v stream reqd (Request_logger.register +> Auth.register ~env +> close))
;;

let connection_handler ~sw ~env ~db:_ server =
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

let serve ~env ~sw ~port ~db =
  let net = Eio.Stdenv.net env in
  let addr = `Tcp (Eio.Net.Ipaddr.V4.loopback, port) in
  let module M = struct
    let run_usecase th = Handler.v ~db th

    let get_user_id () =
      Eio.Fiber.get Context.user_id
      |> Option.map ~f:Domains.Objects.User.Id.to_
      |> Result.of_option ~error:(`Not_ok Grpc.Status.Unauthenticated)
    ;;
  end
  in
  let handler = connection_handler ~env ~sw ~db (services ~env (module M)) in
  let server_socket = Eio.Net.listen net ~sw ~reuse_addr:true ~backlog:128 addr in
  let rec listen () =
    let () = Eio.Net.accept_fork ~sw server_socket ~on_error:raise_notrace handler in
    listen ()
  in
  listen ()
;;

let backoff ~env ~max_retries ~initial_interval ~max_interval f =
  let clock = Eio.Stdenv.clock env in
  let rec loop attempt =
    match f () with
    | Ok _ as res -> res
    | Error err ->
      if attempt >= max_retries
      then Error err
      else (
        (* 1. Calculate Exponential Growth *)
        let backoff = initial_interval *. (2.0 ** float_of_int attempt) in
        (* 2. CAP IT: Never exceed max_interval *)
        let capped_backoff = Float.min backoff max_interval in
        (* 3. Jitter: Randomize to prevent Thundering Herd.
             Using "Full Jitter" strategy: random between 0 and capped_wait. 
             Standard 'Equal Jitter' (wait/2 + random(wait/2)) is also fine, 
             but Full Jitter is statistically better for throughput. *)
        let sleep_time = Random.float capped_backoff in
        Eio.Time.sleep clock sleep_time;
        loop (attempt + 1))
  in
  loop 0
;;

let chehealth ~env ~db =
  Sql.Handler.v db @@ fun () ->
  backoff ~env ~max_retries:5 ~initial_interval:0.5 ~max_interval:5.0 Sql.System.ping
;;
