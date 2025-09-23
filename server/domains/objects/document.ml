module Id = Morph.Seal (struct
    type t = int64 [@@deriving eq]
  end)

module Title = Morph.SealHom (struct
    type t = string [@@deriving eq]

    let field = "title"
    let validate s = Utils.Validator.string s ~min:1 ~max:255
  end)

module Content = Morph.SealHom (struct
    type t = string [@@deriving eq]

    let field = "content"
    let validate s = Utils.Validator.string s ~min:1 ~max:1000000
  end)

module CreatedAt = Morph.Seal (struct
    type t = float [@@deriving eq]
  end)

module UpdatedAt = Morph.Seal (struct
    type t = float [@@deriving eq]
  end)

type t =
  { id : Id.t
  ; organization : Organization.Id.t
  ; title : Title.t
  ; author_id : User.Id.t
  ; content : Content.t
  ; created_at : CreatedAt.t
  ; updated_at : UpdatedAt.t
  }
[@@deriving eq, make]

let id { id; _ } = Id.to_ id
let organization { organization; _ } = Organization.Id.to_ organization
let title { title; _ } = Title.to_ title
let author_id { author_id; _ } = User.Id.to_ author_id
let content { content; _ } = Content.to_ content
let created_at { created_at; _ } = CreatedAt.to_ created_at
let updated_at { updated_at; _ } = UpdatedAt.to_ updated_at
