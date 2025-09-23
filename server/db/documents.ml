module Fwd = Domains.Objects.Document

module T = struct
  module Id = Morph.Iso (struct
      module M = Fwd.Id

      let typ = Caqti_type.int64
    end)

  module AuthorId = Users.T.Id
  module OrganizationId = Organizations.T.Id

  module Content = Morph.Hom (struct
      module M = Fwd.Content

      let typ = Caqti_type.string
    end)

  module Title = Morph.Hom (struct
      module M = Fwd.Title

      let typ = Caqti_type.string
    end)

  module CreatedAt = Morph.Iso (struct
      module M = Fwd.CreatedAt

      let typ = Caqti_type.float
    end)

  module UpdateAt = Morph.Iso (struct
      module M = Fwd.UpdatedAt

      let typ = Caqti_type.float
    end)
end

let create dbh ~title ~content ~author_id ~organization =
  let open Utils.Let.Result in
  let* id, created_at, updated_at =
    [%rapper
      get_one
        {sql|
          INSERT INTO documents (title, content, author_id, organization)
          VALUES (%T.Title{title}, %T.Content{content}, %T.AuthorId{author_id}, %T.OrganizationId{organization})
          RETURNING @T.Id{id},
                    @T.CreatedAt{extract(epoch from created_at)},
                    @T.UpdateAt{extract(epoch from updated_at)}
        |sql}]
      ~title
      ~content
      ~author_id
      ~organization
      dbh
  in
  return @@ Fwd.make ~id ~title ~content ~author_id ~organization ~created_at ~updated_at
;;

let find_by_id dbh id =
  let open Utils.Let.Result in
  let* id, title, content, author_id, organization, created_at, updated_at =
    [%rapper
      get_one
        {sql|
          SELECT @T.Id{id},
                 @T.Title{title},
                 @T.Content{content},
                 @T.AuthorId{author_id},
                 @T.OrganizationId{organization},
                 @T.CreatedAt{extract(epoch from created_at)},
                 @T.UpdateAt{extract(epoch from updated_at)}
          FROM documents
          WHERE id = %int64{id}
        |sql}]
      ~id
      dbh
  in
  return @@ Fwd.make ~id ~title ~content ~author_id ~organization ~created_at ~updated_at
;;
