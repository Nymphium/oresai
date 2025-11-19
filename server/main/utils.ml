let widen_errors = Result.map_error ~f:(fun err -> (err :> Errors.t))
