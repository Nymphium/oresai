open Let.Result
open Alcotest
open Core
open Domains.Objects.Memo
module Model = Testing.Memo

let tests =
  ( "memos"
  , [ ( test_case "insert" `Quick @@ fun () ->
        let user_fx =
          Testing.User.fixture
            ~name:"john smith"
            ~email:"hoge+memos@email.invalid"
            ~display_name:"jsmth"
            ~bio:"hello"
            ()
        in
        let user =
          let hashed_password = Domains.Values.Password.unsafe_from "password" in
          match
            Sql.Users.create
              ~name:
                (Domains.Objects.User.Name.unsafe_from
                 @@ Domains.Objects.User.name user_fx)
              ~email:
                (Domains.Objects.User.Email.unsafe_from
                 @@ Domains.Objects.User.email user_fx)
              ~display_name:
                (Domains.Objects.User.DisplayName.unsafe_from
                 @@ Domains.Objects.User.display_name user_fx)
              ~bio:
                (Domains.Objects.User.Bio.unsafe_from @@ Domains.Objects.User.bio user_fx)
              ?avatar_url:
                (Option.map ~f:Domains.Objects.User.AvatarUrl.unsafe_from
                 @@ Domains.Objects.User.avatar_url user_fx)
              ~links:
                (List.map ~f:Domains.Objects.User.Links.Element.unsafe_from
                 @@ Domains.Objects.User.links user_fx)
              ~hashed_password
              ()
          with
          | Ok user -> user
          | Error e -> failwith @@ Sql.Errors.show e
        in
        let fx =
          Model.fixture
            ~content:"content"
            ~user_id:(Domains.Objects.User.id user)
            ~tags:[]
            ~state:Public
            ()
        in
        let res =
          let { content; user_id; tags; state; _ } = fx in
          Sql.Memos.create ~content ~user_id ~tags ~state
        in
        Alcotest.check'
          (result Model.t Errors.t)
          ~msg:"equal"
          ~expected:(Ok fx)
          ~actual:Model.(res >>| omit_id >>| omit_ts) )
    ] )
;;
