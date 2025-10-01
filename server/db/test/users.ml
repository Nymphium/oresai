open Let.Result
open Alcotest
open Core
open Domains.Objects.User
module Model = Models.User

let tests =
  ( "users"
  , [ (test_case "insert" `Quick
       @@ fun () ->
       let fx =
         Model.fixture
           ~name:"john smith"
           ~email:"hoge@email.invalid"
           ~display_name:"jsmth"
           ~bio:"hello"
           ~avatar_url:"https://example.invalid"
           ()
       in
       let res =
         let hashed_password = Domains.Values.Password.unsafe_from "password" in
         let { name; email; display_name; bio; avatar_url; links; _ } = fx in
         Db.Users.create
           ~name
           ~email
           ~display_name
           ~bio
           ~avatar_url
           ~links
           ~hashed_password
       in
       Alcotest.check'
         (result Model.t Errors.t)
         ~msg:"equal"
         ~expected:(Ok fx)
         ~actual:Model.(res >>| omit_id >>| omit_ts))
    ; (test_case "no verify" `Quick
       @@ fun () ->
       let res = Db.Users.verify 0L >>| Option.map ~f:(Fn.compose Id.to_ fst) in
       Alcotest.check'
         (result (option int64) Errors.t)
         ~msg:"equal"
         ~expected:(Ok None)
         ~actual:res)
    ; (test_case "verify" `Quick
       @@ fun () ->
       let plain = "password" in
       let fx =
         Model.fixture
           ~name:"john smith"
           ~email:"hoge53@email.invalid"
           ~display_name:"jsmth"
           ~bio:"hello"
           ~avatar_url:"https://example.invalid"
           ()
       in
       let user =
         let { name; email; display_name; bio; avatar_url; links; _ } = fx in
         (let hashed_password = Domains.Values.Password.unsafe_from plain in
          Db.Users.create
            ~name
            ~email
            ~display_name
            ~bio
            ~avatar_url
            ~links
            ~hashed_password)
         |> function
         | Error e -> Alcotest.fail @@ Db.Errors.show e
         | Ok user -> user
       in
       let res =
         Db.Users.verify (id user)
         |> Result.map ~f:(Option.map ~f:(Fn.compose Id.to_ fst))
       in
       Alcotest.check'
         (result (option int64) Errors.t)
         ~msg:"equal"
         ~expected:(Ok (Some (id user)))
         ~actual:res)
    ; (test_case "insert_get" `Quick
       @@ fun () ->
       let fx =
         Model.fixture
           ~name:"john smith"
           ~email:"hoge2@email.invalid"
           ~display_name:"jsmth"
           ~bio:"hello"
           ~avatar_url:"https://example.invalid"
           ()
       in
       let t =
         let hashed_password = Domains.Values.Password.unsafe_from "password" in
         let { name; email; display_name; bio; avatar_url; links; _ } = fx in
         Db.Users.create
           ~name
           ~email
           ~display_name
           ~bio
           ~avatar_url
           ~links
           ~hashed_password
       in
       let res =
         match t with
         | Error e -> Alcotest.fail @@ Db.Errors.show e
         | Ok user ->
           Alcotest.check'
             Model.t
             ~msg:"equal"
             ~expected:fx
             ~actual:Model.(user |> omit_id |> omit_ts);
           user
       in
       let res' = Db.Users.find_by_id (id res) in
       Alcotest.check'
         (result (option Model.t) Errors.t)
         ~msg:"equal"
         ~expected:(Ok (Some fx))
         ~actual:Model.(res' >>| Option.map ~f:omit_ts >>| Option.map ~f:omit_id))
    ; (test_case "links" `Quick
       @@ fun () ->
       let fx =
         Model.fixture
           ~name:"john smith"
           ~email:"hoge3@email.invalid"
           ~display_name:"jsmth"
           ~bio:"hello"
           ~avatar_url:"https://example.invalid"
           ~links:
             [ "https://example2.invalid"
             ; "https://example3.invalid"
             ; "https://example4.invalid"
             ]
           ()
       in
       let t =
         let hashed_password = Domains.Values.Password.unsafe_from "password" in
         let { name; email; display_name; bio; avatar_url; links; _ } = fx in
         Db.Users.create
           ~name
           ~email
           ~display_name
           ~bio
           ~avatar_url
           ~links
           ~hashed_password
       in
       let t =
         match t with
         | Error e -> Alcotest.fail @@ Db.Errors.show e
         | Ok user ->
           Alcotest.check'
             Model.t
             ~msg:"equal"
             ~expected:fx
             ~actual:Model.(user |> omit_id |> omit_ts);
           user
       in
       Alcotest.check' int ~msg:"length" ~expected:3 ~actual:List.(length @@ links t))
    ; (test_case "empty update" `Quick
       @@ fun () ->
       let fx =
         Model.fixture
           ~name:"john smith"
           ~email:"hoge4@email.invalid"
           ~display_name:"jsmth"
           ~bio:"hello"
           ~avatar_url:"https://example.invalid"
           ~links:
             [ "https://example2.invalid"
             ; "https://example3.invalid"
             ; "https://example4.invalid"
             ]
           ()
       in
       let t =
         let hashed_password = Domains.Values.Password.unsafe_from "password" in
         let { name; email; display_name; bio; avatar_url; links; _ } = fx in
         Db.Users.create
           ~name
           ~email
           ~display_name
           ~bio
           ~avatar_url
           ~links
           ~hashed_password
       in
       let user =
         match t with
         | Error e -> Alcotest.fail @@ Db.Errors.show e
         | Ok t ->
           check' int ~msg:"precheck" ~expected:3 ~actual:(links t |> List.length);
           t
       in
       let user' = Db.Users.update user.id () in
       Alcotest.check'
         (result Model.t Errors.t)
         ~msg:"updated"
         ~expected:(Ok fx)
         ~actual:Model.(user' >>| omit_id >>| omit_ts))
    ; (test_case "update" `Quick
       @@ fun () ->
       let fx =
         Model.fixture
           ~name:"john smith"
           ~email:"hoge5@email.invalid"
           ~display_name:"jsmth"
           ~bio:"hello"
           ~avatar_url:"https://example.invalid"
           ~links:[ "https://example2.invalid" ]
           ()
       in
       let t =
         let hashed_password = Domains.Values.Password.unsafe_from "password" in
         let { name; email; display_name; bio; avatar_url; links; _ } = fx in
         Db.Users.create
           ~name
           ~email
           ~display_name
           ~bio
           ~avatar_url
           ~links
           ~hashed_password
       in
       let user =
         match t with
         | Error e -> Alcotest.fail @@ Db.Errors.show e
         | Ok t -> t
       in
       let bio = Bio.unsafe_from "world" in
       let user' = Db.Users.update user.id ~bio () in
       Alcotest.check'
         (result Model.t Errors.t)
         ~msg:"updated"
         ~expected:(Ok { fx with bio })
         ~actual:Model.(user' >>| omit_id >>| omit_ts))
    ] )
;;
