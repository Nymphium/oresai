open Core
module Fwd = Domains.Objects.User

module Model = struct
  type t = Fwd.t

  module Id = Morph.Iso (struct
      module M = Fwd.Id

      let typ = Caqti_type.int64
    end)

  module Password = Morph.Hom (struct
      module M = Domains.Values.Password

      let typ = Caqti_type.string
    end)

  (** users_links *)
  module Links = struct
    (** element of links *)
    module Element = Values.Model.Url

    type t = Id.t * Element.t

    let t =
      let base_t = Caqti_type.(Std.t2 int64 string) in
      let encode (l, r) = Result.return (Fwd.Id.to_ l, Domains.Values.Url.to_ r) in
      let decode (l, r) =
        Result.return (Fwd.Id.from l, Domains.Values.Url.unsafe_from r)
      in
      Caqti_type.custom ~encode ~decode base_t
    ;;
  end

  (** omitted password *)
  let t =
    let base_t = Caqti_type.(Std.t7 int64 string string string string string ptime) in
    let encode fwd =
      let open Let.Result in
      let* created_at' =
        Fwd.created_at fwd |> Ptime.of_float_s |> Result.of_option ~error:"created_at"
      in
      return
        Fwd.(
          ( id fwd
          , name fwd
          , email fwd
          , display_name fwd
          , bio fwd
          , avatar_url fwd
          , created_at' ))
    in
    let decode (id, name, email, display_name, bio, avatar_url, created_at) =
      let id = Fwd.Id.from id in
      let name = Fwd.Name.unsafe_from name in
      let display_name = Fwd.DisplayName.unsafe_from display_name in
      let email = Fwd.Email.unsafe_from email in
      let bio = Fwd.Bio.unsafe_from bio in
      let avatar_url = Domains.Values.Url.unsafe_from avatar_url in
      let created_at = created_at |> Ptime.to_float_s |> Fwd.CreatedAt.from in
      Result.return
      @@ Fwd.make ~id ~name ~display_name ~email ~bio ~avatar_url ~created_at ~links:[]
    in
    Caqti_type.custom ~encode ~decode base_t
  ;;

  module Returning = struct
    type t = Fwd.Id.t * Fwd.CreatedAt.t

    let t =
      let base_t = Caqti_type.(Std.t2 int64 ptime) in
      let encode (l, r) =
        let open Let.Result in
        let id = Fwd.Id.to_ l in
        let* created_at =
          r
          |> Fwd.CreatedAt.to_
          |> Ptime.of_float_s
          |> Result.of_option ~error:"created_at"
        in
        return (id, created_at)
      in
      let decode (l, r) =
        let id = Fwd.Id.from l in
        let created_at = r |> Ptime.to_float_s |> Fwd.CreatedAt.from in
        Result.return (id, created_at)
      in
      Caqti_type.custom ~encode ~decode base_t
    ;;
  end
end

open struct
  module Links = struct
    let list db id =
      [%rapper
        get_many
          {|
            SELECT @Model.Links.Element{url}
            FROM users_links
            WHERE user_id = %Model.Id{id}
          |}]
        db
        ~id
    ;;

    (** [set_links] sets links to users_links.
      XXX: It runs SQL query [length links] times!!! See {https://github.com/roddyyaga/ppx_rapper/issues/44}  *)
    let set db id links =
      Result.all_unit
      @@ List.map links ~f:(fun url ->
        [%rapper
          execute
            {|
              INSERT INTO users_links (user_id, url)
              VALUES (%Model.Id{id}, %Model.Links.Element{url})
            |}]
          db
          ~id
          ~url)
    ;;
  end
end

(** [verify] *verifies* the given [id] and returns the proper id type with
    password if it exists in the DB. *)
let verify id =
  let db = Effect.perform @@ Effects.Get_conn in
  [%rapper
    get_opt
      {|
        SELECT @Model.Id{id}, @Model.Password{hashed_password}
        FROM users
        WHERE id = %int64{id}
      |}]
    ~id
    db
;;

let create ~name ~email ~display_name ~bio ~hashed_password:password ~avatar_url ~links =
  let db = Effect.perform @@ Effects.Transaction in
  let open Let.Result in
  let* id, created_at =
    [%rapper
      get_one
        {|
          INSERT INTO users (name, email, display_name, bio, hashed_password, avatar_url)
          VALUES (%string{name}, %string{email}, %string{display_name}, %string{bio}, %Model.Password{password},  %string{avatar_url})
          RETURNING @Model.Returning{id, created_at}
        |}]
      ~name:(Fwd.Name.to_ name)
      ~email:(Fwd.Email.to_ email)
      ~display_name:(Fwd.DisplayName.to_ display_name)
      ~bio:(Fwd.Bio.to_ bio)
      ~avatar_url:(Fwd.AvatarUrl.to_ avatar_url)
      ~password
      db
  in
  let* () = if List.is_empty links then Result.return () else Links.set db id links in
  return @@ Fwd.make ~id ~name ~email ~display_name ~bio ~avatar_url ~links ~created_at
;;

(** [update] updates the target id with the given fields. If [links] is [None],
    then nothing changes. Otherwise, [links] is updated to that list; i.e., if
    [Some []] is given, then all the links are removed. *)
let update id ?name ?email ?display_name ?bio ?password ?avatar_url ?links () =
  let db = Effect.perform @@ Effects.Transaction in
  let name = Option.map ~f:Fwd.Name.to_ name in
  let email = Option.map ~f:Fwd.Email.to_ email in
  let display_name = Option.map ~f:Fwd.DisplayName.to_ display_name in
  let bio = Option.map ~f:Fwd.Bio.to_ bio in
  let password = Option.map ~f:Domains.Values.Password.to_ password in
  let avatar_url = Option.map ~f:Fwd.AvatarUrl.to_ avatar_url in
  let open Let.Result in
  let* t =
    [%rapper
      get_one
        {|
          UPDATE users
          SET
            name = COALESCE(%string?{name}, name),
            email = COALESCE(%string?{email}, email),
            display_name = COALESCE(%string?{display_name}, display_name),
            bio = COALESCE(%string?{bio}, bio),
            avatar_url = COALESCE(%string?{avatar_url}, avatar_url),
            hashed_password = COALESCE(%string?{password}, hashed_password)
          WHERE id = %Model.Id{id}
          RETURNING @Model{id, name, email, display_name, bio, avatar_url, created_at}
        |}]
      ~id
      ~email
      ~name
      ~display_name
      ~bio
      ~password
      ~avatar_url
      db
  in
  match links with
  | None -> Links.list db t.id >>| fun links -> { t with links }
  | Some links ->
    let* () =
      [%rapper execute {| DELETE FROM users_links WHERE user_id = %Model.Id{id} |}] db ~id
    in
    if List.is_empty links
    then return t
    else
      let* () = Links.set db t.id links in
      return { t with links }
;;

let find_by_id id =
  let db = Effect.perform @@ Effects.Transaction in
  let open Let.Result in
  let* t =
    [%rapper
      get_opt
        {|
          SELECT @Model{id, name, email, display_name, bio, avatar_url, created_at}
          FROM users
          WHERE id = %int64{id}
        |}]
      ~id
      db
  in
  match t with
  | None -> return None
  | Some t ->
    let* links = Links.list db t.id in
    return @@ Some { t with links }
;;

let find_by_email email =
  let db = Effect.perform @@ Effects.Transaction in
  let open Let.Result in
  let* t =
    [%rapper
      get_opt
        {|
          SELECT @Model{id, name, email, display_name, bio, avatar_url, created_at}
          FROM users
          WHERE email = %string{email}
        |}]
      ~email
      db
  in
  match t with
  | None -> return None
  | Some t ->
    let* links = Links.list db t.id in
    return @@ Some { t with links }
;;

let check_password id raw_password =
  let db = Effect.perform @@ Effects.Transaction in
  let open Let.Result in
  let* password =
    [%rapper
      get_one
        {|
        SELECT @string{hashed_password}
        FROM users
        WHERE id = %Model.Id{id}
      |}]
      ~id
      db
  in
  Domains.Values.Password.verify
    ~hashed:(Domains.Values.Password.unsafe_from password)
    ~plain:raw_password
;;
