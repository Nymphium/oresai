let () =
  Eio_main.run @@ fun _ ->
  let clock = Eio_mock.Clock.make () in
  Alcotest.run
    "usecases"
    [ System_ping.test
    ; Get_user_by_email.test
    ; Get_user_by_id.test
    ; Access_token.test ~clock
    ; Register_user.test
    ; User_create_memo.test
    ; User_create_article.test
    ]
;;
