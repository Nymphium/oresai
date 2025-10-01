module Id = Morph.Seal (struct
    type t = int64 [@@deriving eq, show { with_path = false }]
  end)

module Name = Morph.SealHom (struct
    type t = string [@@deriving eq, show { with_path = false }]

    let field = "name"
    let validate s = Validator.string s ~min:1 ~max:50
  end)

module UserId = User.Id

type t =
  { id : Id.t
  ; name : Name.t
  ; user_id : UserId.t
  }
[@@deriving eq, make, show { with_path = false }]

let id { id; _ } = Id.to_ id
let name { name; _ } = Name.to_ name
let user_id { user_id; _ } = UserId.to_ user_id
