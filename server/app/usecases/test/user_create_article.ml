module Errors' = Errors
open Alcotest
open Usecases
open Domains.Repositories
module M = User_create_article

let test =
  ( "user_create_article"
  , [ ( test_case "ok" `Quick @@ fun () ->
        let fixture = Testing.Article.fixture () in
        let run th =
          try th () with
          | effect
              Locator.Inject
                (Article.Create { title; content; user_id; tag_ids = _; state }), k ->
            Alcotest.check'
              (module Domains.Objects.Article.Title)
              ~msg:"same title"
              ~expected:fixture.title
              ~actual:title;
            Alcotest.check'
              (module Domains.Objects.Article.Content)
              ~msg:"same content"
              ~expected:fixture.content
              ~actual:content;
            Alcotest.check'
              (module Domains.Objects.Article.UserId)
              ~msg:"same user_id"
              ~expected:fixture.user_id
              ~actual:user_id;
            Alcotest.check'
              (module Domains.Objects.Article.State)
              ~msg:"same state"
              ~expected:fixture.state
              ~actual:state;
            Effect.Deep.continue k (Ok fixture)
          | _ -> failwith "unmatched"
        in
        let actual =
          run @@ fun () ->
          M.run
            ~user_id:(Domains.Objects.User.Id.to_ fixture.user_id)
            ~title:(Domains.Objects.Article.Title.to_ fixture.title)
            ~content:(Domains.Objects.Article.Content.to_ fixture.content)
            ~tag_ids:[]
            ~state:(Domains.Objects.Article.State.to_ fixture.state)
            ()
        in
        Alcotest.check'
          (result Testing.Article.t Errors'.t)
          ~msg:"equal"
          ~expected:(Ok fixture)
          ~actual )
    ; ( test_case "empty title" `Quick @@ fun () ->
        let run th =
          try th () with
          | _ -> failwith "should not be called"
        in
        let actual =
          run @@ fun () ->
          M.run ~user_id:0L ~title:"" ~content:"content" ~tag_ids:[] ~state:"draft" ()
        in
        Alcotest.check'
          (result Testing.Article.t Errors'.t)
          ~msg:"equal"
          ~expected:(Error (`ConvertError "title"))
          ~actual )
    ; ( test_case "empty content" `Quick @@ fun () ->
        let run th =
          try th () with
          | _ -> failwith "should not be called"
        in
        let actual =
          run @@ fun () ->
          M.run ~user_id:0L ~title:"title" ~content:"" ~tag_ids:[] ~state:"draft" ()
        in
        Alcotest.check'
          (result Testing.Article.t Errors'.t)
          ~msg:"equal"
          ~expected:(Error (`ConvertError "content"))
          ~actual )
    ; ( test_case "invalid state" `Quick @@ fun () ->
        let run th =
          try th () with
          | _ -> failwith "should not be called"
        in
        let actual =
          run @@ fun () ->
          M.run
            ~user_id:0L
            ~title:"title"
            ~content:"content"
            ~tag_ids:[]
            ~state:"invalid"
            ()
        in
        Alcotest.check'
          (result Testing.Article.t Errors'.t)
          ~msg:"equal"
          ~expected:(Error (`ConvertError "state"))
          ~actual )
    ] )
;;
