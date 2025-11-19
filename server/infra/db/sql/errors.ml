include Domains.Errors

let caqti_to_domain : [> Caqti_error.t ] -> Domains.Errors.t = function
  | #Caqti_error.t as err -> `InternalError (Caqti_error.show err)
;;

let or_not_found ~resource ~id =
  Core.Result.bind ~f:(Core.Result.of_option ~error:(`NotFound (resource, id)))
;;

let to_domain ?(resource = "") ?(id = "")
  :  ( 'a
       , [> Caqti_error.call_or_retrieve
         | Caqti_error.load
         | Caqti_error.t
         | `Connect_failed of Caqti_error.connection_error
         | `Connect_rejected of Caqti_error.connection_error
         | Domains.Errors.t
         ] )
       Result.t
  -> ('a, [> Domains.Errors.t ]) Result.t
  =
  Result.map_error @@ function
  | `Unique_violation -> `DuplicateEntry (resource, id)
  | `Foreign_key_violation -> `ReferenceError (resource, id)
  | `Connect_failed _ -> `InternalError "connection failed"
  | `Connect_rejected _ -> `InternalError "connection rejected"
  | #Caqti_error.load as e -> `InternalError (Caqti_error.show e)
  | #Caqti_error.call_or_retrieve as e -> `InternalError (Caqti_error.show e)
  | #Caqti_error.t as e -> `InternalError (Caqti_error.show e)
  | #Domains.Errors.t as e -> e
;;

let to_domain_opt ~resource ~id =
  Fun.compose (to_domain ~resource ~id) (or_not_found ~resource ~id)
;;
