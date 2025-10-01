module Fwd = Domains.Objects.Memo

module Model = struct
  module Returning = struct
    type t = Fwd.Id.t * Fwd.CreatedAt.t * Fwd.UpdatedAt.t

    let t =
      let base_t = Caqti_type.(Std.t3 int64 ptime ptime) in
      let encode (id, created_at, updated_at) =
        let open Let.Result in
        let id = Fwd.Id.to_ id in
        let* created_at =
          created_at
          |> Fwd.CreatedAt.to_
          |> Ptime.of_float_s
          |> function
          | Some p -> Ok p
          | None -> Error "created_at"
        in
        let* updated_at =
          updated_at
          |> Fwd.UpdatedAt.to_
          |> Ptime.of_float_s
          |> function
          | Some p -> Ok p
          | None -> Error "updated_at"
        in
        return (id, created_at, updated_at)
      in
      let decode (id, created_at, updated_at) =
        let id = Fwd.Id.from id in
        let created_at = created_at |> Ptime.to_float_s |> Fwd.CreatedAt.from in
        let updated_at = updated_at |> Ptime.to_float_s |> Fwd.UpdatedAt.from in
        Result.ok (id, created_at, updated_at)
      in
      Caqti_type.custom ~encode ~decode base_t
    ;;
  end

  module Id = Morph.Iso (struct
      module M = Fwd.Id

      let typ = Caqti_type.int64
    end)

  (** articles_tags *)
  module Tags = struct
    module Element = Tags.Model

    type t = Id.t * Tags.Model.Id.t

    let base_t = Caqti_type.(Std.t2 int64 int64)
    let encode (l, r) = Result.ok (Fwd.Id.to_ l, Fwd.TagId.to_ r)
    let decode (l, r) = Result.ok (Fwd.Id.from l, Fwd.TagId.from r)
    let t = Caqti_type.custom ~encode ~decode base_t
  end

  type t = Fwd.t

  let t =
    let base_t = Caqti_type.(Std.t6 int64 int64 string string ptime ptime) in
    let encode fwd =
      let open Let.Result in
      let* created_at =
        Fwd.created_at fwd
        |> Ptime.of_float_s
        |> function
        | Some p -> Ok p
        | None -> Error "created_at"
      in
      let* updated_at =
        Fwd.updated_at fwd
        |> Ptime.of_float_s
        |> function
        | Some p -> Ok p
        | None -> Error "updated_at"
      in
      return
        ( Fwd.id fwd
        , Fwd.user_id fwd
        , Fwd.content fwd
        , Fwd.state fwd
        , created_at
        , updated_at )
    in
    let decode (id, user_id, content, state, created_at, updated_at) =
      let id = Fwd.Id.from id in
      let user_id = Domains.Objects.User.Id.from user_id in
      let content = Fwd.Content.unsafe_from content in
      let state = Fwd.State.unsafe_from state in
      let created_at = created_at |> Ptime.to_float_s |> Fwd.CreatedAt.from in
      let updated_at = updated_at |> Ptime.to_float_s |> Fwd.UpdatedAt.from in
      Result.ok @@ Fwd.make ~id ~user_id ~content ~state ~created_at ~updated_at ()
    in
    Caqti_type.custom ~encode ~decode base_t
  ;;
end

(** [verify] *verifies* the given [id] and returns the proper id type if it exists in the DB. *)
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

(** [create]s a new {Domains.Objects.Memo.t}. [tag_ids] is a *raw* id list and is validated by retrieving from the database. *)
let create ~content ~user_id ~tag_ids ~state =
  let db = Effect.perform @@ Effects.Get_conn in
  let open Let.Result in
  let* id, created_at, updated_at =
    [%rapper
      get_one
        {sql|
          INSERT INTO articles (content, user_id, state)
          VALUES (%string{content}, %int64{user_id}, %string{state})
          RETURNING @Model.Returning{id, created_at, updated_at}
        |sql}]
      ~content:(Fwd.Content.to_ content)
      ~user_id:(Fwd.UserId.to_ user_id)
      ~state:(Fwd.State.to_ state)
      db
  in
  let tag_ids = List.map Domains.Objects.Tag.Id.from tag_ids in
  (* This also validates that each id in tag_ids is valid. *)
  let* () =
    let tags = List.map (fun tag_id -> id, tag_id) tag_ids in
    [%rapper
      execute
        {sql|
          INSERT INTO articles_tags
          VALUES (%list{%Model.Tags{tags}})
        |sql}]
      db
      ~tags
  in
  return @@ Fwd.make ~id ~content ~user_id ~tag_ids ~created_at ~updated_at ~state ()
;;

let find_by_id id =
  let db = Effect.perform @@ Effects.Get_conn in
  let open Let.Result in
  let* t =
    [%rapper
      get_one
        {sql|
          SELECT @Model{id, user_id,  content, state, created_at, updated_at}
          FROM articles
          WHERE id = %int64{id}
        |sql}]
      ~id
      db
  in
  let* tag_ids =
    [%rapper
      get_many
        {sql|
          SELECT @Model.Tags.Element.Id{tag_id}
          FROM articles_tags
          WHERE id = %int64{id}
        |sql}]
      ~id
      db
  in
  return @@ { t with tag_ids }
;;
