module Errors' = Errors
open Alcotest
open Usecases

let test =
  ( "access_token"
  , [ ( test_case "ok" `Quick @@ fun () ->
        let fixture = Testing.User.fixture ~id:0L () in
        let actual =
          let comp () =
            let open Let.Result in
            let* token = User_create_auth_token.run (Domains.Objects.User.id fixture) in
            Get_user_id_from_access_token.run token
          in
          let trace th =
            let run r =
              match r () with
              | effect Services.Auth.Token.Create_with_user_id _, k ->
                fun record ->
                  Effect.Deep.continue k (Ok "") (record @ [ "create_with_user_id" ])
              | effect Services.Auth.Token.Confirm _, k ->
                fun record -> Effect.Deep.continue k (Ok 0L) (record @ [ "confirm" ])
              | x -> fun y -> x, y
            in
            run th []
          in
          snd @@ trace comp
        in
        check'
          (list string)
          ~msg:"right effect trace"
          ~expected:[ "create_with_user_id"; "confirm" ]
          ~actual )
    ] )
;;
