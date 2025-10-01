module Id = Morph.Seal (struct
    type t = int64 [@@deriving eq, show { with_path = false }]
  end)

module UserId = User.Id

module Content = Morph.SealHom (struct
    type t = string [@@deriving eq, show { with_path = false }]

    let field = "content"
    let validate s = Validator.string s ~min:1 ~max:1000000
  end)

module TagId = Tag.Id

module CreatedAt = Morph.Seal (struct
    type t = float [@@deriving eq, show { with_path = false }]
  end)

module UpdatedAt = Morph.Seal (struct
    type t = float [@@deriving eq, show { with_path = false }]
  end)

module State = struct
  type t =
    | Draft
    | Published
    | Archived
  [@@deriving eq, show { with_path = false }]

  type bwd = string [@@deriving eq, show { with_path = false }]

  let to_ = show

  let from = function
    | "draft" -> Ok Draft
    | "published" -> Ok Published
    | "archived" -> Ok Archived
    | _ -> Error (`ConvertError "state")
  ;;

  let unsafe_from = Fun.compose Result.get_ok from
  let validate = Fun.compose Result.is_ok from
end

type t =
  { id : Id.t
  ; user_id : UserId.t
  ; content : Content.t
  ; tag_ids : TagId.t list
  ; state : State.t
  ; created_at : CreatedAt.t
  ; updated_at : UpdatedAt.t
  }
[@@deriving eq,make, show { with_path = false }]

let id { id; _ } = Id.to_ id
let user_id { user_id; _ } = UserId.to_ user_id
let content { content; _ } = Content.to_ content
let tags { tag_ids; _ } = List.map TagId.to_ tag_ids
let state { state; _ } = State.show state
let created_at { created_at; _ } = CreatedAt.to_ created_at
let updated_at { updated_at; _ } = UpdatedAt.to_ updated_at
