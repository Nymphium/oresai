module Errors' = Errors
open Alcotest
open Usecases
open Domains.Repositories
module M = Register_user

let test =
  ( "register_user"
  , [ ( test_case "ok" `Quick @@ fun () ->
        let fixture =
          Testing.User.fixture
            ~name:"test"
            ~email:"test@example.com"
            ~display_name:"Test User"
            ~bio:"bio"
            ()
        in
        let inj : type a. a Locator.action -> a = function
          | User.(
              Create
                { name
                ; email
                ; display_name
                ; bio
                ; avatar_url = _
                ; password = _
                ; links = _
                }) ->
            Alcotest.check'
              (module Domains.Objects.User.Name)
              ~msg:"same name"
              ~expected:(Domains.Objects.User.Name.unsafe_from "test")
              ~actual:name;
            Alcotest.check'
              (module Domains.Objects.User.Email)
              ~msg:"same email"
              ~expected:(Domains.Objects.User.Email.unsafe_from "test@example.com")
              ~actual:email;
            Alcotest.check'
              (module Domains.Objects.User.DisplayName)
              ~msg:"same display_name"
              ~expected:(Domains.Objects.User.DisplayName.unsafe_from "Test User")
              ~actual:display_name;
            Alcotest.check'
              (module Domains.Objects.User.Bio)
              ~msg:"same bio"
              ~expected:(Domains.Objects.User.Bio.unsafe_from "bio")
              ~actual:bio;
            Ok fixture
          | _ -> failwith "unmatched"
        in
        let actual =
          let comp () =
            M.run
              ~name:"test"
              ~email:"test@example.com"
              ~password:"password"
              ~display_name:"Test User"
              ~bio:"bio"
              ~links:[]
              ()
            |> Result.map Domains.Objects.User.Id.to_
          in
          try comp () with
          | effect Locator.Inject action, k -> Effect.Deep.continue k (inj action)
        in
        Alcotest.check'
          (result int64 Errors'.t)
          ~msg:"equal"
          ~expected:(Ok (Domains.Objects.User.id fixture))
          ~actual )
    ; ( test_case "invalid email" `Quick @@ fun () ->
        let inj : type a. a Locator.action -> a = function
          | _ -> failwith "should not be called"
        in
        let actual =
          let comp () =
            M.run
              ~name:"test"
              ~email:"invalid"
              ~password:"password"
              ~display_name:"Test User"
              ~bio:"bio"
              ~links:[]
              ()
            |> Result.map Domains.Objects.User.Id.to_
          in
          try comp () with
          | effect Locator.Inject action, k -> Effect.Deep.continue k (inj action)
        in
        Alcotest.check'
          (result int64 Errors'.t)
          ~msg:"equal"
          ~expected:(Error (`ConvertError "email"))
          ~actual )
    ; ( test_case "name too long" `Quick @@ fun () ->
        let inj : type a. a Locator.action -> a = function
          | _ -> failwith "should not be called"
        in
        let actual =
          let comp () =
            M.run
              ~name:(String.make 101 'a')
              ~email:"test@example.com"
              ~password:"password"
              ~display_name:"Test User"
              ~bio:"bio"
              ~links:[]
              ()
            |> Result.map Domains.Objects.User.Id.to_
          in
          try comp () with
          | effect Locator.Inject action, k -> Effect.Deep.continue k (inj action)
        in
        Alcotest.check'
          (result int64 Errors'.t)
          ~msg:"equal"
          ~expected:(Error (`ConvertError "name"))
          ~actual )
    ; ( test_case "display_name too long" `Quick @@ fun () ->
        let inj : type a. a Locator.action -> a = function
          | _ -> failwith "should not be called"
        in
        let actual =
          let comp () =
            M.run
              ~name:"test"
              ~email:"test@example.com"
              ~password:"password"
              ~display_name:(String.make 101 'a')
              ~bio:"bio"
              ~links:[]
              ()
            |> Result.map Domains.Objects.User.Id.to_
          in
          try comp () with
          | effect Locator.Inject action, k -> Effect.Deep.continue k (inj action)
        in
        Alcotest.check'
          (result int64 Errors'.t)
          ~msg:"equal"
          ~expected:(Error (`ConvertError "display_name"))
          ~actual )
    ; ( test_case "bio too long" `Quick @@ fun () ->
        let inj : type a. a Locator.action -> a = function
          | _ -> failwith "should not be called"
        in
        let actual =
          let comp () =
            M.run
              ~name:"test"
              ~email:"test@example.com"
              ~password:"password"
              ~display_name:"Test User"
              ~bio:(String.make 501 'a')
              ~links:[]
              ()
            |> Result.map Domains.Objects.User.Id.to_
          in
          try comp () with
          | effect Locator.Inject action, k -> Effect.Deep.continue k (inj action)
        in
        Alcotest.check'
          (result int64 Errors'.t)
          ~msg:"equal"
          ~expected:(Error (`ConvertError "bio"))
          ~actual )
    ] )
;;
