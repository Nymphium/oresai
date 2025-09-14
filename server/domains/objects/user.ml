open struct
  module Id = Util.Iso (struct
      type t = int [@@deriving eq]
    end)

  module Name = Util.Hom (struct
      type t = string [@@deriving eq]

      let validator =
        Utils.Validator.make
          ~report:(fun s ->
            Printf.sprintf
              "Name must be between 1 and 100 characters long, got %d"
              (String.length s))
          ~validate:(fun s -> String.length s > 0 && String.length s <= 100)
      ;;
    end)

  module Email = Util.Hom (struct
      type t = string [@@deriving eq]

      let validator =
        Utils.Validator.make
          ~report:(fun s -> Printf.sprintf "Invalid email format: %s" s)
          ~validate:(fun s ->
            let re = Str.regexp "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]+$" in
            Str.string_match re s 0)
      ;;
    end)

  module CreatedAt = Util.Iso (struct
      type t = int64 [@@deriving eq]
    end)
end

type t =
  { id : Id.t
  ; name : Name.t
  ; email : Email.t
  ; created_at : CreatedAt.t (** unix time *)
  }
[@@deriving eq]

let id { id; _ } = Id.to_ id
let name { name; _ } = Name.to_ name
let email { email; _ } = Email.to_ email
let created_at { created_at; _ } = CreatedAt.to_ created_at

let create ~id ~name ~email ~created_at =
  let open Utils.Let.Result in
  let id = Id.from id in
  let* name = Name.from name in
  let* email = Email.from email in
  let created_at = CreatedAt.from created_at in
  return { id; name; email; created_at }
;;
