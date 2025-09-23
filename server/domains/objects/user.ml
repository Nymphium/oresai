module Id = Morph.Seal (struct
    type t = int64 [@@deriving eq]
  end)

module Name = Morph.SealHom (struct
    type t = string [@@deriving eq]

    let field = "name"
    let validate s = Utils.Validator.string s ~min:0 ~max:100
  end)

module Email = Morph.SealHom (struct
    type t = string [@@deriving eq]

    let field = "email"

    let validate s =
      Utils.Validator.string s ~regexp:{|^[^@ \t\r\n]+@[^@ \t\r\n]+\.[^@ \t\r\n]+$|}
    ;;
  end)

module CreatedAt = Morph.Seal (struct
    type t = float [@@deriving eq]
  end)

type t =
  { id : Id.t
  ; name : Name.t
  ; email : Email.t
  ; created_at : CreatedAt.t (** unix time *)
  }
[@@deriving eq, make]

let id { id; _ } = Id.to_ id
let name { name; _ } = Name.to_ name
let email { email; _ } = Email.to_ email
let created_at { created_at; _ } = CreatedAt.to_ created_at
