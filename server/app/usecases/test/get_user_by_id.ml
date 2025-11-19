module Errors' = Errors
open Alcotest
open Usecases
open Domains.Repositories
module M = Get_user_by_id

let test =
  ( "get_user_by_id"
  , [ ( test_case "ok" `Quick @@ fun () ->
        let fixture = Testing.User.fixture ~id:0L () in
        let inj : type a. a Locator.action -> a = function
          | User.(FindById { user_id = 0L }) -> Ok (Some fixture)
          | User.(CheckPassword { user_id; password = _ }) ->
            if Domains.Objects.User.Id.equal user_id fixture.id then Ok true else Ok false
          | _ -> failwith "unmatched"
        in
        let actual =
          let comp () = M.run ~user_id:0L in
          try comp () with
          | effect Locator.Inject action, k -> Effect.Deep.continue k (inj action)
        in
        Alcotest.check'
          (result Testing.User.t Errors'.t)
          ~msg:"equal"
          ~expected:(Ok fixture)
          ~actual )
    ; ( test_case "not found" `Quick @@ fun () ->
        let inj : type a. a Locator.action -> a = function
          | User.(FindById _) -> Ok None
          | _ -> failwith "unmatched"
        in
        let actual =
          let comp () = M.run ~user_id:0L in
          try comp () with
          | effect Locator.Inject action, k -> Effect.Deep.continue k (inj action)
        in
        Alcotest.check'
          (result Testing.User.t Errors'.t)
          ~msg:"equal"
          ~expected:(Error `Invalid_user_id)
          ~actual )
    ] )
;;
