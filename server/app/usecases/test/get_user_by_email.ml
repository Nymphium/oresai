module Errors' = Errors
open Alcotest
open Usecases
open Domains.Repositories
module M = Get_user_by_email

let test =
  ( "get_user_by_email"
  , [ ( test_case "ok" `Quick @@ fun () ->
        let fixture = Testing.User.fixture ~email:"ok@example.invalid" () in
        let inj : type a. a Locator.action -> a = function
          | User.(FindByEmail { email = "ok@example.invalid" }) -> Ok (Some fixture)
          | User.(FindByEmail _) -> Ok None
          | User.(CheckPassword { user_id; password = _ }) ->
            if Domains.Objects.User.Id.equal user_id fixture.id then Ok true else Ok false
          | _ -> failwith "unmatched"
        in
        let actual =
          let comp () = M.run ~email:fixture.email ~password:"" in
          try comp () with
          | effect Locator.Inject action, k -> Effect.Deep.continue k (inj action)
        in
        Alcotest.check'
          (result Testing.User.t Errors'.t)
          ~msg:"equal"
          ~expected:(Ok fixture)
          ~actual )
    ; ( test_case "not found" `Quick @@ fun () ->
        let fixture = Testing.User.fixture ~email:"ok@example.invalid" () in
        let inj : type a. a Locator.action -> a = function
          | User.(FindByEmail _) -> Ok None
          | _ -> failwith "unmatched"
        in
        let actual =
          let comp () = M.run ~email:fixture.email ~password:"" in
          try comp () with
          | effect Locator.Inject action, k -> Effect.Deep.continue k (inj action)
        in
        Alcotest.check'
          (result Testing.User.t Errors'.t)
          ~msg:"equal"
          ~expected:(Error `Missing_user_id)
          ~actual )
    ] )
;;
