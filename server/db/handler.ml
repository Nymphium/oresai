open Effect.Shallow
open Let.Result

(** Connection handler: if in a transaction, then enter the transaction context; otherwise, it starts a transaction.
      [finally] runs before closing transaction. *)
let v ?(finally = Fun.const Result.ok) pool th =
  pool
  |> Caqti_eio.Pool.use
     @@ fun conn ->
     let module DB = (val conn : Rapper_helper.CONNECTION) in
     let rec handler =
       { effc =
           (fun (type b) (eff : b Effect.t) ->
             match eff with
             | Effects.Get_conn ->
               Some (fun (k : (b, _) continuation) -> continue_with k conn handler)
             | Effects.Transaction ->
               Some (fun (k : (b, _) continuation) -> continue_with k conn handler)
             | _ -> None)
       ; retc = Fun.id
       ; exnc = raise
       }
     in
     let entry =
       { effc =
           (fun (type b) (eff : b Effect.t) ->
             match eff with
             | Effects.Get_conn ->
               Some (fun (k : (b, _) continuation) -> continue_with k conn handler)
             | Effects.Transaction ->
               Some
                 (fun (k : (b, _) continuation) ->
                   DB.with_transaction
                   @@ fun () -> continue_with k conn handler >>= finally conn)
             | _ -> None)
       ; retc = Fun.id
       ; exnc = raise
       }
     in
     entry |> continue_with (fiber th) ()
;;
