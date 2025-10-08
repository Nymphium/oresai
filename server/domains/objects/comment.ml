module Id = Morph.Seal (struct
    type t = int64 [@@deriving eq, show { with_path = false }]
  end)

module TargetId = struct
  type t =
    | Article of Article.Id.t
    | Memo of Memo.Id.t
  [@@deriving eq, show { with_path = false }]
end

module Content = Morph.SealHom (struct
    type t = string [@@deriving eq, show { with_path = false }]

    let field = "content"
    let validate s = Validator.string s ~min:1 ~max:10000
  end)

module CreatedAt = Morph.Seal (struct
    type t = float [@@deriving eq, show { with_path = false }]
  end)

type t =
  { id : Id.t
  ; target_id : TargetId.t
  ; user_id : User.Id.t
  ; content : Content.t
  ; created_at : CreatedAt.t
  }
[@@deriving eq, make, show { with_path = false }]
