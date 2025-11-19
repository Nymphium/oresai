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
    | Public
    | Private
  [@@deriving eq, show { with_path = false }]

  type bwd = string [@@deriving eq, show { with_path = false }]

  let to_ = function
    | Public -> "public"
    | Private -> "private"
  ;;

  let from = function
    | "public" -> Ok Public
    | "private" -> Ok Private
    | _ -> Error (`ConvertError "state")
  ;;

  let unsafe_from = Fun.compose Result.get_ok from
  let validate = Fun.compose Result.is_ok from
end

type t =
  { id : Id.t
  ; user_id : UserId.t
  ; content : Content.t
  ; tags : Tag.t list
  ; state : State.t
  ; created_at : CreatedAt.t
  ; updated_at : UpdatedAt.t
  }
[@@deriving eq, make, show { with_path = false }]

let id { id; _ } = Id.to_ id
let user_id { user_id; _ } = UserId.to_ user_id
let content { content; _ } = Content.to_ content
let tags { tags; _ } = tags
let state { state; _ } = State.show state
let created_at { created_at; _ } = CreatedAt.to_ created_at
let updated_at { updated_at; _ } = UpdatedAt.to_ updated_at
