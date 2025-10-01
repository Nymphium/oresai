open Core

let () =
  (function
    | Error e -> failwith @@ Db.Errors.show e
    | Ok () -> ())
  @@ Eio_main.run
  @@ fun stdenv ->
  Eio.Switch.run
  @@ fun sw ->
  let open Let.Result in
  let* conn =
    Caqti_eio_unix.connect_pool ~sw ~stdenv:(stdenv :> Caqti_eio.stdenv)
    @@ Uri.of_string "pgx://root@localhost:15432/oresai?sslmode=disable"
  in
  Db.Handler.v
    ~finally:(fun conn v ->
      let module DB = (val conn) in
      DB.rollback () >>| Fun.const v)
    conn
  @@ fun () -> return @@ Alcotest.run "db" [ Dbh.tests; Users.tests ]
;;
