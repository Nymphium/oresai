open Effect.Shallow
open Let.Result

(** Connection handler: if in a transaction, then enter the transaction context;
    otherwise, it starts a transaction. [finally] runs before closing
    transaction. *)
let v
  :  ?finally:
       ((module Rapper_helper.CONNECTION) -> 'm -> ('m, [> Domains.Errors.t ]) Result.t)
  -> (Caqti_eio.connection, [> Domains.Errors.t ]) Caqti_eio.Pool.t
  -> (unit -> ('a, [> Domains.Errors.t ]) Result.t)
  -> ('a, [> Domains.Errors.t ]) Result.t
  =
  let caqti_run
    :  ?priority:float
    -> ('conn -> ('a, [> Caqti_error.t ]) Result.t)
    -> ('conn, [> Caqti_error.t ]) Caqti_eio.Pool.t
    -> ('a, [> Caqti_error.t ]) Result.t
    =
    fun ?priority t m ->
    (Obj.magic Caqti_eio.Pool.use
     : ?priority:float
       -> ('conn -> ('a, [> Caqti_error.t ]) Result.t)
       -> ('conn, [> Caqti_error.t ]) Caqti_eio.Pool.t
       -> ('a, [> Caqti_error.t ]) Result.t)
      ?priority
      t
      m
  in
  fun ?(finally = fun _conn v -> Result.ok v) pool th ->
    let th : unit -> ('a, [> Domains.Errors.t ]) Result.t = Obj.magic th in
    pool
    |> caqti_run (fun conn ->
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
                    DB.with_transaction @@ fun () ->
                    continue_with k conn handler >>= finally conn)
              | _ -> None)
        ; retc = Fun.id
        ; exnc = raise
        }
      in
      entry |> continue_with (fiber th) ())
    |> Errors.to_domain
;;
