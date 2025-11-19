module Errors' = Errors
open Alcotest
open Usecases
open Domains.Repositories
module M = System_ping

let test =
  ( "system_ping"
  , [ ( test_case "ok" `Quick @@ fun () ->
        let run th =
          try th () with
          | effect Locator.Inject System.Ping, k -> Effect.Deep.continue k @@ Ok ()
          | _ -> failwith "unmatched"
        in
        let actual = run M.run in
        Alcotest.check' (result unit Errors'.t) ~msg:"equal" ~expected:(Ok ()) ~actual )
    ] )
;;
