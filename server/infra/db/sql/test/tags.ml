open Let.Result
open Alcotest
open Core
open Domains.Objects.Tag
module Model = Testing.Tag

let tests =
  ( "tags"
  , [ ( test_case "create" `Quick @@ fun () ->
        let user =
          let fx =
            Testing.User.fixture
              ~name:"john smith"
              ~email:"hoge+tags@email.invalid"
              ~display_name:"jsmth"
              ~bio:"hello"
              ()
          in
          let hashed_password = Domains.Values.Password.unsafe_from "password" in
          let Domains.Objects.User.
                { name; email; display_name; bio; avatar_url; links; _ }
            =
            fx
          in
          Sql.Users.create
            ~name
            ~email
            ~display_name
            ~bio
            ?avatar_url
            ~links
            ~hashed_password
            ()
          |> function
          | Error e -> fail @@ Sql.Errors.show e
          | Ok u -> u
        in
        let fx = Model.fixture ~name:"hello" ~user_id:(Domains.Objects.User.id user) () in
        let res = Sql.Tags.create fx.name fx.user_id in
        Alcotest.check'
          (result Model.t Errors.t)
          ~msg:"equal"
          ~expected:(Ok fx)
          ~actual:(res >>| Model.omit_id) )
    ] )
;;
