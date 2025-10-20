open Core

let main ~env ~sw ~conn Config.{ port; _ } () =
  Eio.Fiber.with_binding Context.conn conn @@ fun () ->
  Logs.info (fun m -> m "Starting gRPC server on port %d" port);
  try Result.return @@ Server.serve ~env ~sw ~port with
  | Eio.Cancel.Cancelled _ -> Ok ()
;;

let shutdown = function
  | i when i = Stdlib.Sys.sigint ->
    Logs.info (fun m -> m "Shutting down gracefully");
    Result.return ()
  | signal ->
    Logs.info (fun m -> m "Received signal: %d" signal);
    Result.return ()
;;

let () =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let stdout = Eio.Stdenv.stdout env in
  let () =
    Logs.(
      set_reporter (Logs_compat.reporter ~env ~sw ~stdout);
      set_level @@ Some Debug);
    let level' =
      Oenv.read Logs_compat.Level.reader |> function
      | Ok lv -> Some lv
      | Error err ->
        (failwithf "failed to parse log level: %s" @@ Oenv.Errors.show err) ()
    in
    Logs.Src.set_level Caqti_platform.Logging.default_log_src level';
    Logs.Src.set_level Caqti_platform.Logging.request_log_src level';
    Logs.(set_level level')
  in
  let signal, resolver = Eio.Promise.create () in
  let () =
    Stdlib.Sys.(
      set_signal sigpipe @@ Signal_ignore;
      set_signal sigint @@ Signal_handle (Eio.Promise.resolve resolver))
  in
  let open Let.Result in
  ( function
    | Ok _ -> ()
    | Error err -> Logs.err (fun m -> m "%a" Errors.pp err) )
  @@ map_error ~f:(fun exn -> `Exn exn)
  @@ try_with
  @@ fun () ->
  let* ({ db_dsn; _ } as config) = Config.read () in
  let* conn = Caqti_eio_unix.connect_pool ~sw ~stdenv:(env :> Caqti_eio.stdenv) db_dsn in
  Eio.Fiber.any
    [ main ~env ~sw ~conn config; (fun () -> Eio.Promise.await signal |> shutdown) ]
;;
