(** @see User.Id *)
module UserId = User.Id

module Nickname = Morph.SealHom (struct
    type t = string [@@deriving eq]

    let field = "nickname"
    let validate s = Utils.Validator.string s ~min:1 ~max:100
  end)

(** TODO: string option *)
module Profile = Morph.SealHom (struct
    type t = string [@@deriving eq]

    let field = "profile"
    let validate s = Utils.Validator.string s ~max:500
  end)

module Links = Morph.SealHom (struct
    type t = string list [@@deriving eq]

    let field = "links"

    let validate lst =
      let element s =
        Utils.Validator.string
          s
          ~regexp:
            {|https?://(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()!@:%_\+.~#?&//=]*)|}
      in
      Utils.Validator.list lst ~element ~min:0 ~max:10
    ;;
  end)

module BirthDate = Morph.Seal (struct
    type t = int64 [@@deriving eq]
  end)

type t =
  { user_id : UserId.t
  ; nickname : Nickname.t
  ; profile : Profile.t
  ; birth_date : BirthDate.t (** unix time; time is ignorable *)
  }
[@@deriving eq, make]

let user_id { user_id; _ } = UserId.to_ user_id
let nickname { nickname; _ } = Nickname.to_ nickname
let profile { profile; _ } = Profile.to_ profile
let birth_date { birth_date; _ } = BirthDate.to_ birth_date
