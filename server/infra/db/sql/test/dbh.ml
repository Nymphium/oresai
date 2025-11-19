open Let.Result
open Alcotest
open Core

let tests =
  ( "dbh"
  , [ ( test_case "flat transaction" `Quick @@ fun () ->
        let actual =
          let* db =
            Result.(Fn.compose (map_error ~f:Exn.to_string) try_with) @@ fun () ->
            let db = Effect.perform Sql.Effects.Transaction in
            let _ = Effect.perform Sql.Effects.Transaction in
            let _ = Effect.perform Sql.Effects.Transaction in
            let _ = Effect.perform Sql.Effects.Transaction in
            db
          in
          [%rapper get_one {sql| SELECT @int{42} |sql}] () db
          |> Sql.Errors.to_domain
          |> Result.map_error ~f:Sql.Errors.show
        in
        Alcotest.check' (result int string) ~msg:"ok" ~expected:(Ok 42) ~actual )
    ] )
;;
