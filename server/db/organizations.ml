module Fwd = Domains.Objects.Organization

module T = struct
  module Id = Morph.Iso (struct
      module M = Fwd.Id

      let typ = Caqti_type.int64
    end)

  module Name = Morph.Hom (struct
      module M = Fwd.Name

      let typ = Caqti_type.string
    end)

  module CreatedAt = Morph.Iso (struct
      module M = Fwd.CreatedAt

      let typ = Caqti_type.float
    end)
end

let create dbh ~name =
  let open Utils.Let.Result in
  [%rapper
    get_one
      {sql|
          INSERT INTO organizations (name)
          VALUES (%T.Name{name})
          RETURNING @T.Id{id}, @T.CreatedAt{extract(epoch from created_at)}
        |sql}]
    ~name
    dbh
  >>| fun (id, created_at) -> Fwd.make ~id ~name ~created_at
;;

let find_by_id dbh id =
  let open Utils.Let.Result in
  [%rapper
    get_opt
      {sql|
          SELECT @T.Id{id}, @T.Name{name}, @T.CreatedAt{extract(epoch from created_at)}
          FROM organizations
          WHERE id = %int64{id}
        |sql}]
    ~id
    dbh
  >>= (function
    | None -> Error (`NotFound "organization")
    | Some (id, name, created_at) -> return@@ Fwd.make ~id ~name ~created_at )
;;
