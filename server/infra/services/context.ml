let conn : (Caqti_eio.connection, Errors.t) Caqti_eio.Pool.t Eio.Fiber.key =
  Eio.Fiber.create_key ()
;;

let user_id : Domains.Objects.User.Id.t Eio.Fiber.key = Eio.Fiber.create_key ()
