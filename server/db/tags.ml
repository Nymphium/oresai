open Core

open struct
  module Fwd = Domains.Objects.Tag
end

module Model = struct
  module Id = Morph.Iso (struct
      module M = Fwd.Id

      let typ = Caqti_type.int64
    end)

  module Name = Morph.Hom (struct
      module M = Fwd.Name

      let typ = Caqti_type.string
    end)

  module UserId = Users.Model.Id

  type t = Fwd.t

  let t =
    let base_t = Caqti_type.(Std.t3 int64 string int64) in
    let encode fwd = Result.return (Fwd.id fwd, Fwd.name fwd, Fwd.user_id fwd) in
    let decode (id, name, user_id) =
      let open Let.Result in
      let id = Fwd.Id.from id in
      let* name = Fwd.Name.from name >>? Domains.Errors.show in
      let user_id = Domains.Objects.User.Id.from user_id in
      return @@ Fwd.make ~id ~name ~user_id
    in
    Caqti_type.custom ~encode ~decode base_t
  ;;
end

(** [verify] *verifies* the given [id] and returns the proper id type if it
    exists in the DB. *)
let verify id =
  let db = Effect.perform @@ Effects.Get_conn in
  [%rapper
    get_opt
      {sql|
      SELECT @Model.Id{id}
      FROM users
      WHERE id = %int64{id}
      |sql}]
    ~id
    db
;;

let create name user_id =
  let db = Effect.perform @@ Effects.Get_conn in
  let open Let.Result in
  [%rapper
    get_one
      {sql|
        INSERT INTO tags (name, user_id)
        VALUES (%string{name}, %int64{user_id})
        RETURNING @Model.Id{id}
      |sql}]
    db
    ~name:(Fwd.Name.to_ name)
    ~user_id:(Fwd.UserId.to_ user_id)
  >>| fun id -> Fwd.make ~id ~user_id ~name
;;

let list_by_user_id user_id =
  let db = Effect.perform @@ Effects.Get_conn in
  [%rapper
    get_many
      {sql|
        SELECT @Model{id, name, user_id}
        FROM tags
        WHERE user_id = %Model.UserId{user_id}
      |sql}]
    db
    ~user_id
;;
