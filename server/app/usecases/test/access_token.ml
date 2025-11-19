module Errors' = Errors
open Alcotest
open Usecases

let test ~clock =
  ( "access_token"
  , [ ( test_case "ok" `Quick @@ fun () ->
        let fixture = Testing.User.fixture ~id:0L () in
        let actual =
          let open Let.Result in
          let* token = User_create_auth_token.run ~user:fixture ~clock in
          Get_user_id_from_access_token.run ~clock token
        in
        check' (result int64 Errors'.t) ~msg:"equal" ~expected:(Ok 0L) ~actual )
    ; ( test_case "invalid token" `Quick @@ fun () ->
        let actual = Get_user_id_from_access_token.run ~clock "invalid" in
        check'
          (result int64 Errors'.t)
          ~msg:"equal"
          ~expected:(Error (`DecryptionError "Bad token"))
          ~actual )
    ; ( test_case "expired token" `Quick @@ fun () ->
        let fixture = Testing.User.fixture ~id:0L () in
        let token = User_create_auth_token.run ~user:fixture ~clock |> Result.get_ok in
        Eio_mock.Clock.set_time clock 3600.;
        let actual = Get_user_id_from_access_token.run ~clock token in
        check'
          (result int64 Errors'.t)
          ~msg:"equal"
          ~expected:(Error (`DecryptionError "Expired signature"))
          ~actual )
    ] )
;;
