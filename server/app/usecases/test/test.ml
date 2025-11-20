let () =
  Alcotest.run
    "usecases"
    [ System_ping.test
    ; Get_user_by_email.test
    ; Get_user_by_id.test
    ; Access_token.test
    ; Register_user.test
    ; User_create_memo.test
    ; User_create_article.test
    ]
;;
