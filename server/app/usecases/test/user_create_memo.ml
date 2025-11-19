module Errors' = Errors
open Alcotest
open Usecases
open Domains.Repositories
module M = User_create_memo

let test =
  ( "user_create_memo"
  , [ ( test_case "ok" `Quick @@ fun () ->
        let fixture = Testing.Memo.fixture () in
        let runner : type a. a Locator.action -> a = function
          | Memo.(Create { content; user_id; tag_ids = _; state }) ->
            Alcotest.check'
              (module Domains.Objects.Memo.Content)
              ~msg:"same content"
              ~expected:fixture.content
              ~actual:content;
            Alcotest.check'
              (module Domains.Objects.Memo.UserId)
              ~msg:"same user_id"
              ~expected:fixture.user_id
              ~actual:user_id;
            Alcotest.check'
              (module Domains.Objects.Memo.State)
              ~msg:"same state"
              ~expected:fixture.state
              ~actual:state;
            Ok fixture
          | _ -> failwith "unmatched"
        in
        let actual =
          let comp () =
            M.run
              ~user_id:(Domains.Objects.User.Id.to_ fixture.user_id)
              ~content:(Domains.Objects.Memo.Content.to_ fixture.content)
              ~tag_ids:[]
              ~state:(Domains.Objects.Memo.State.to_ fixture.state)
              ()
          in
          try comp () with
          | effect Locator.Inject action, k -> Effect.Deep.continue k (runner action)
        in
        Alcotest.check'
          (result Testing.Memo.t Errors'.t)
          ~msg:"equal"
          ~expected:(Ok fixture)
          ~actual )
    ; ( test_case "empty content" `Quick @@ fun () ->
        let runner : type a. a Locator.action -> a = function
          | _ -> failwith "should not be called"
        in
        let actual =
          let comp () = M.run ~user_id:0L ~content:"" ~tag_ids:[] ~state:"public" () in
          try comp () with
          | effect Locator.Inject action, k -> Effect.Deep.continue k (runner action)
        in
        Alcotest.check'
          (result Testing.Memo.t Errors'.t)
          ~msg:"equal"
          ~expected:(Error (`ConvertError "content"))
          ~actual )
    ; ( test_case "invalid state" `Quick @@ fun () ->
        let runner : type a. a Locator.action -> a = function
          | _ -> failwith "should not be called"
        in
        let actual =
          let comp () =
            M.run ~user_id:0L ~content:"memo" ~tag_ids:[] ~state:"invalid" ()
          in
          try comp () with
          | effect Locator.Inject action, k -> Effect.Deep.continue k (runner action)
        in
        Alcotest.check'
          (result Testing.Memo.t Errors'.t)
          ~msg:"equal"
          ~expected:(Error (`ConvertError "state"))
          ~actual )
    ] )
;;
