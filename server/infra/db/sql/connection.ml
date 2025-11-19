let create ~sw ~env url
  : ( (Caqti_eio.connection, [> Caqti_error.t ]) Caqti_eio.Pool.t
      , [> Domains.Errors.t ] )
      Result.t
  =
  Caqti_eio_unix.connect_pool ~sw ~stdenv:(env :> Caqti_eio.stdenv) url
  |> Errors.to_domain
;;
