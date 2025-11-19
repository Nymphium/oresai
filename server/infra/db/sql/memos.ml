open Core

open struct
  module Fwd = Domains.Objects.Memo

  let resource = "memos"

  let error_to_domain ?id =
    Errors.to_domain ~resource ?id:(Option.map ~f:Int64.to_string id)
  ;;
end

module Model = struct
  module Returning = struct
    type t = Fwd.Id.t * Fwd.CreatedAt.t * Fwd.UpdatedAt.t

    let t =
      let base_t = Caqti_type.(Std.t3 int64 ptime ptime) in
      let encode (id, created_at, updated_at) =
        let open Let.Result in
        let id = Fwd.Id.to_ id in
        let* created_at =
          created_at |> Fwd.CreatedAt.to_ |> Ptime.of_float_s |> function
          | Some p -> Ok p
          | None -> Error "created_at"
        in
        let* updated_at =
          updated_at |> Fwd.UpdatedAt.to_ |> Ptime.of_float_s |> function
          | Some p -> Ok p
          | None -> Error "updated_at"
        in
        return (id, created_at, updated_at)
      in
      let decode (id, created_at, updated_at) =
        let id = Fwd.Id.from id in
        let created_at = created_at |> Ptime.to_float_s |> Fwd.CreatedAt.from in
        let updated_at = updated_at |> Ptime.to_float_s |> Fwd.UpdatedAt.from in
        Result.return (id, created_at, updated_at)
      in
      Caqti_type.custom ~encode ~decode base_t
    ;;
  end

  module Id = Morph.Iso (struct
      module M = Fwd.Id

      let typ = Caqti_type.int64
    end)

  module Content = Morph.Hom (struct
      module M = Fwd.Content

      let typ = Caqti_type.string
    end)

  module State = struct
    type t = Fwd.State.t

    let t =
      let base_t = Caqti_type.string in
      let encode s = s |> Fwd.State.to_ |> String.lowercase |> Result.return in
      let decode = Fun.compose Result.return Fwd.State.unsafe_from in
      Caqti_type.custom ~encode ~decode base_t
    ;;
  end

  (** articles_tags *)
  module Tags = struct
    module Element = Tags.Model

    type t = Id.t * Tags.Model.Id.t

    let base_t = Caqti_type.(Std.t2 int64 int64)
    let encode (l, r) = Result.return (Fwd.Id.to_ l, Fwd.TagId.to_ r)
    let decode (l, r) = Result.return (Fwd.Id.from l, Fwd.TagId.from r)
    let t = Caqti_type.custom ~encode ~decode base_t
  end

  type t = Fwd.t

  let t =
    let base_t = Caqti_type.(Std.t6 int64 int64 string string ptime ptime) in
    let encode fwd =
      let open Let.Result in
      let* created_at =
        Fwd.created_at fwd |> Ptime.of_float_s |> function
        | Some p -> Ok p
        | None -> Error "created_at"
      in
      let* updated_at =
        Fwd.updated_at fwd |> Ptime.of_float_s |> function
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
      Result.return @@ Fwd.make ~id ~user_id ~content ~state ~created_at ~updated_at ()
    in
    Caqti_type.custom ~encode ~decode base_t
  ;;
end

(** [verify] *verifies* the given [id] and returns the proper id type if it
    exists in the DB. *)
let verify id =
  let db = Effect.perform @@ Effects.Get_conn in
  error_to_domain
  @@ [%rapper
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
let create ~content ~user_id ~tags ~state =
  let db = Effect.perform @@ Effects.Get_conn in
  let open Let.Result in
  error_to_domain
  @@
  let* id, created_at, updated_at =
    [%rapper
      get_one
        {sql|
          INSERT INTO memos (content, user_id, state)
          VALUES (%Model.Content{content}, %Users.Model.Id{user_id}, %Model.State{state})
          RETURNING @Model.Returning{id, created_at, updated_at}
        |sql}]
      ~content
      ~user_id
      ~state
      db
  in
  (* This also validates each id in tag_ids is valid, i.e., in DB. *)
  let* () =
    if List.is_empty tags
    then return ()
    else (
      let tag_pairs = List.map ~f:(fun tag -> id, tag.Domains.Objects.Tag.id) tags in
      [%rapper
        execute
          {sql|
          INSERT INTO memos_tags
          VALUES (%list{%Model.Tags{tag_pairs}})
        |sql}]
        db
        ~tag_pairs)
  in
  return @@ Fwd.make ~id ~content ~user_id ~tags ~created_at ~updated_at ~state ()
;;

let find_by_id id =
  let db = Effect.perform @@ Effects.Get_conn in
  let open Let.Result in
  error_to_domain ~id
  @@
  let* t =
    [%rapper
      get_one
        {sql|
          SELECT @Model{id, user_id,  content, state, created_at, updated_at}
          FROM memos
          WHERE id = %int64{id}
        |sql}]
      ~id
      db
  in
  let* tags =
    [%rapper
      get_many
        {sql|
          SELECT @Tags.Model{tags.id, tags.name, tags.user_id}
          FROM tags
          JOIN memos_tags ON tags.id = memos_tags.tag_id
          WHERE memos_tags.memo_id = %Model.Id{id}
        |sql}]
      ~id:t.id
      db
  in
  return @@ { t with tags }
;;

let list_by_user_id user_id =
  let db = Effect.perform @@ Effects.Get_conn in
  let open Let.Result in
  error_to_domain
  @@
  let* memos =
    [%rapper
      get_many
        {sql|
          SELECT @Model{id, user_id, content, state, created_at, updated_at}
          FROM memos
          WHERE user_id = %Users.Model.Id{user_id}
        |sql}]
      ~user_id
      db
  in
  (* TODO: add tags *)
  return memos
;;
