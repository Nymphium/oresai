let ping () =
  Errors.to_domain
  @@
  let db = Effect.perform @@ Effects.Get_conn in
  [%rapper
    get_one
      {|
        SELECT true; -- connection check
      |}]
    ()
    db
;;
