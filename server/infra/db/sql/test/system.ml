open Let.Result
open Alcotest

let tests =
  ( "system"
  , [ ( test_case "ping" `Quick @@ fun () ->
        let res = Sql.System.ping () in
        Alcotest.check' (result unit Errors.t) ~msg:"equal" ~expected:(Ok ()) ~actual:res
      )
    ] )
;;
