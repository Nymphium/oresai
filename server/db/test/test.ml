open Core

let () =
  ( function
    | Error e -> failwith @@ Db.Errors.show e
    | Ok () -> () )
  @@ Eio_main.run
  @@ fun stdenv ->
  Eio.Switch.run @@ fun sw ->
  let stdout = Eio.Stdenv.stdout stdenv in
  Logs.set_reporter @@ Logs_compat.reporter ~env:stdenv ~sw ~stdout;
  Logs.(set_level @@ Some Debug);
  let url =
    Uri.make
      ~scheme:"postgresql"
      ~host:(Sys.getenv_exn "PGHOST")
      ~port:(Sys.getenv_exn "PGPORT" |> Int.of_string)
      ~path:("/" ^ Sys.getenv_exn "PGDATABASE")
      ~query:[ "sslmode", [ "disable" ] ]
      ()
  in
  let open Let.Result in
  let* conn = Caqti_eio_unix.connect_pool ~sw ~stdenv:(stdenv :> Caqti_eio.stdenv) url in
  Db.Handler.v
    ~finally:(fun conn v ->
      let module DB = (val conn) in
      DB.rollback () >>| Fun.const v)
    conn
  @@ fun () -> return @@ Alcotest.run "db" [ Dbh.tests; Users.tests ]
;;
