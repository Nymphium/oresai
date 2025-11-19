open Core

let _ =
  ( function
    | Error e -> failwith @@ Domains.Errors.show e
    | Ok () -> () )
  @@ Eio_main.run
  @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let stdout = Eio.Stdenv.stdout env in
  Logs.set_reporter @@ Logs_compat.reporter ~env ~sw ~stdout;
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
  let* conn = Sql.Connection.create ~sw ~env url in
  Sql.Handler.v
    ~finally:(fun conn v ->
      let module DB = (val conn) in
      DB.rollback () >>| Fun.const v)
    conn
  @@ fun () ->
  return
  @@ Alcotest.run
       "db"
       [ Dbh.tests; Users.tests; Articles.tests; Memos.tests; Tags.tests; System.tests ]
;;
