type _ Effect.t +=
  | Get_pool : (Caqti_eio.connection, Db.Errors.t) Caqti_eio.Pool.t Effect.t

let with_transaction th =
  let pool = Effect.perform Get_pool in
  let open Let.Result in
  ignore
  @@ Db.Handler.v
       ~finally:(fun conn v ->
         let module DB = (val conn) in
         DB.rollback () >>| Fun.const v)
       pool
       (fun () -> th () |> Result.ok)
;;
