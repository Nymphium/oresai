module Fwd = Domains.Objects.User

module T = struct
  module Id = Morph.Iso (struct
      module M = Fwd.Id

      let typ = Caqti_type.int64
    end)

  module Name = Morph.Hom (struct
      module M = Fwd.Name

      let typ = Caqti_type.string
    end)

  module Email = Morph.Hom (struct
      module M = Fwd.Email

      let typ = Caqti_type.string
    end)

  module CreatedAt = Morph.Iso (struct
      module M = Fwd.CreatedAt

      let typ = Caqti_type.float
    end)
end

let create dbh ~name ~email =
  let open Utils.Let.Result in
  [%rapper
    get_one
      {sql|
          INSERT INTO users (name, email)
          VALUES (%T.Name{name}, %T.Email{email})
          RETURNING @T.Id{id}, @T.CreatedAt{extract(epoch from created_at)}
        |sql}]
    ~name
    ~email
    dbh
  >>| fun (id, created_at) -> Fwd.make ~id ~name ~email ~created_at
;;

let find_by_id dbh id =
  let open Utils.Let.Result in
  [%rapper
    get_opt
      {sql|
          SELECT @T.Id{id}, @T.Name{name}, @T.Email{email}, @T.CreatedAt{extract(epoch from created_at)}
          FROM users
          WHERE id = %int64{id}
        |sql}]
    ~id
    dbh
  >>= function
  | None -> Error (`NotFound "user")
  | Some (id, name, email, created_at) -> return @@ Fwd.make ~id ~name ~email ~created_at
;;

let find_by_email dbh email =
  let open Utils.Let.Result in
  [%rapper
    get_opt
      {sql|
          SELECT @T.Id{id}, @T.Name{name}, @T.Email{email}, @T.CreatedAt{extract(epoch from created_at)}
          FROM users
          WHERE email = %string{email}
        |sql}]
    ~email
    dbh
  >>= function
  | None -> Error (`NotFound "user")
  | Some (id, name, email, created_at) -> return @@ Fwd.make ~id ~name ~email ~created_at
;;
