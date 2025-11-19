let dbdsn_reader =
  let make_db_dsn host port database =
    Uri.make
      ~scheme:"postgresql"
      ~host
      ~port
      ~path:("/" ^ database)
      ~query:[ "sslmode", [ "disable" ] ]
      ()
  in
  Oenv.(
    Product.(
      v make_db_dsn
      +: string "PGHOST" ~secret:false
      +: int "PGPORT" ~secret:false
      +: string "PGDATABASE" ~secret:false
      |> close))
;;

type t =
  { db_dsn : Uri.t
  ; port : int
  }

let read () =
  Oenv.(
    Product.(
      v (fun db_dsn port -> { db_dsn; port })
      +: dbdsn_reader
      +: (int "PORT" ~secret:false |> optional |> default 50051)
      |> close)
    |> read)
;;
