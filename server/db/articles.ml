open Core

open struct
  module Fwd = Domains.Objects.Article
end

module Model = struct
  module Id = Morph.Iso (struct
      module M = Fwd.Id

      let typ = Caqti_type.int64
    end)

  (** articles_tags *)
  module Tags = struct
    module Element = Tags.Model

    type t = Id.t * Tags.Model.Id.t

    let t =
      let base_t = Caqti_type.(Std.t2 int64 int64) in
      let encode (l, r) = Result.return (Fwd.Id.to_ l, Domains.Objects.Tag.Id.to_ r) in
      let decode (l, r) = Result.return (Fwd.Id.from l, Domains.Objects.Tag.Id.from r) in
      Caqti_type.custom ~encode ~decode base_t
    ;;
  end

  type t = Fwd.t

  let t =
    let base_t = Caqti_type.(Std.t7 int64 int64 string string string ptime ptime) in
    let encode fwd =
      let open Let.Result in
      let* created_at' =
        Fwd.created_at fwd |> Ptime.of_float_s |> Result.of_option ~error:"created_at"
      in
      let* updated_at' =
        Fwd.updated_at fwd |> Ptime.of_float_s |> Result.of_option ~error:"updated_at"
      in
      return
        Fwd.(
          id fwd, user_id fwd, title fwd, content fwd, state fwd, created_at', updated_at')
    in
    let decode (id, user_id, title, content, state, created_at, updated_at) =
      let id = Fwd.Id.from id in
      let user_id = Domains.Objects.User.Id.from user_id in
      let title = Fwd.Title.unsafe_from title in
      let content = Fwd.Content.unsafe_from content in
      let state = Fwd.State.unsafe_from state in
      let created_at = created_at |> Ptime.to_float_s |> Fwd.CreatedAt.from in
      let updated_at = updated_at |> Ptime.to_float_s |> Fwd.UpdatedAt.from in
      Result.return
      @@ Fwd.make ~id ~user_id ~title ~content ~state ~created_at ~updated_at ()
    in
    Caqti_type.custom ~encode ~decode base_t
  ;;

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
          |> Result.of_option ~error:"created_at"
        in
        let* updated_at =
          updated_at
          |> Fwd.UpdatedAt.to_
          |> Ptime.of_float_s
          |> Result.of_option ~error:"updated_at"
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
end

open struct
  module Tags = struct
    let list db id =
      [%rapper
        get_many
          {sql|
          SELECT @Model.Tags.Element.Id{tag_id}
          FROM articles_tags
          WHERE id = %Model.Id{id}
        |sql}]
        ~id
        db
    ;;

    (** [set_links] sets tags to articles_tags. It also verifies each tag id exists if it can be inserted.
        XXX: It runs SQL query [length links] times!!! See {https://github.com/roddyyaga/ppx_rapper/issues/44}  *)
    let set db id raw_tags =
      Result.all_unit
      @@ List.map raw_tags ~f:(fun tag ->
        [%rapper
          execute
            {|
              INSERT INTO articles_tags
              VALUES (%Model.Id{id}, %int64{tag})
            |}]
          db
          ~id
          ~tag)
    ;;
  end
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

let create ~title ~content ~user_id ~tag_ids ~state =
  let db = Effect.perform @@ Effects.Get_conn in
  let open Let.Result in
  let* id, created_at, updated_at =
    [%rapper
      get_one
        {sql|
          INSERT INTO articles (title, content, user_id, state)
          VALUES (%string{title}, %string{content}, %int64{user_id}, %string{state})
          RETURNING @Model.Returning{id, created_at, updated_at}
        |sql}]
      ~title:(Fwd.Title.to_ title)
      ~content:(Fwd.Content.to_ content)
      ~user_id:(Fwd.UserId.to_ user_id)
      ~state:(Fwd.State.to_ state)
      db
  in
  (* There also validartes each id in tag_ids is valid. *)
  let* () = Tags.set db id tag_ids in
  let tags = List.map ~f:Domains.Objects.Tag.Id.from tag_ids in
  return @@ Fwd.make ~id ~title ~content ~user_id ~tags ~created_at ~updated_at ~state ()
;;

(** [update] updates the target id with the given fields. If [tag_ids] is [None], then nothing changes.
    Otherwise, [tag_ids] is updated to that list; i.e., if [Some []] is given, then all the tags are unrelated. *)
let update id ?title ?content ?tag_ids ?state () =
  let db = Effect.perform @@ Effects.Transaction in
  let title = Option.map ~f:Fwd.Title.to_ title in
  let content = Option.map ~f:Fwd.Content.to_ content in
  let state = Option.map ~f:Fwd.State.to_ state in
  let open Let.Result in
  let* t =
    [%rapper
      get_one
        {|
          UPDATE articles
          SET
            title = COALESCE(%string?{title}, title),
            content = COALESCE(%string?{content}, content),
            state = COALESCE(%string?{state}, state)
          WHERE id = %Model.Id{id}
          RETURNING @Model{id, title, content, state, created_at}
        |}]
      ~id
      ~title
      ~content
      ~state
      db
  in
  match tag_ids with
  | None -> Tags.list db t.id >>| fun tags -> { t with tags }
  | Some tags ->
    let* () =
      [%rapper execute {| DELETE FROM users_links WHERE user_id = %Model.Id{id} |}] db ~id
    in
    if List.is_empty tags
    then return t
    else
      let* () = Tags.set db t.id tags in
      let tags = List.map ~f:Fwd.TagId.from tags in
      return { t with tags }
;;

let find_by_id id =
  let db = Effect.perform @@ Effects.Get_conn in
  let open Let.Result in
  let* t =
    [%rapper
      get_one
        {sql|
          SELECT @Model{id, user_id, title, content, state, created_at, updated_at}
          FROM articles
          WHERE id = %int64{id}
        |sql}]
      ~id
      db
  in
  let* tags = Tags.list db t.id in
  return @@ { t with tags }
;;
