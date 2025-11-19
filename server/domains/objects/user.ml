open Core

module Id = Morph.Seal (struct
    type t = int64 [@@deriving eq, show { with_path = false }]
  end)

module Name = Morph.SealHom (struct
    type t = string [@@deriving eq, show { with_path = false }]

    let field = "name"
    let validate s = Validator.string s ~min:0 ~max:100
  end)

module Email = Morph.SealHom (struct
    type t = string [@@deriving eq, show { with_path = false }]

    let field = "email"

    let validate s =
      Validator.string s ~regexp:{|^[^@ \t\r\n]+@[^@ \t\r\n]+\.[^@ \t\r\n]+$|}
    ;;
  end)

module DisplayName = Morph.SealHom (struct
    type t = string [@@deriving eq, show { with_path = false }]

    let field = "display_name"
    let validate s = Validator.string s ~min:0 ~max:100
  end)

module Bio = Morph.SealHom (struct
    type t = string [@@deriving eq, show { with_path = false }]

    let field = "bio"
    let validate s = Validator.string s ~min:0 ~max:500
  end)

module AvatarUrl = Values.Url

module Links = struct
  module Element = Values.Url

  type t = Element.t list [@@deriving eq, show { with_path = false }]

  let from bwd =
    List.fold_left bwd ~init:(Ok []) ~f:(fun acc url ->
      let open Let.Result in
      let* urls = acc in
      let* url = Element.from url in
      return (url :: urls))
  ;;
end

module CreatedAt = Morph.Seal (struct
    type t = float [@@deriving eq, show { with_path = false }]
  end)

type t =
  { id : Id.t
  ; name : Name.t
  ; email : Email.t
  ; display_name : DisplayName.t
  ; bio : Bio.t
  ; avatar_url : AvatarUrl.t option
  ; links : Links.t
  ; created_at : CreatedAt.t (** unix time *)
  }
[@@deriving eq, make, show { with_path = false }]

let id { id; _ } = Id.to_ id
let name { name; _ } = Name.to_ name
let email { email; _ } = Email.to_ email
let display_name { display_name; _ } = DisplayName.to_ display_name
let bio { bio; _ } = Bio.to_ bio
let avatar_url { avatar_url; _ } = Option.map ~f:Values.Url.to_ avatar_url
let links { links; _ } = List.map ~f:Values.Url.to_ links
let created_at { created_at; _ } = CreatedAt.to_ created_at
