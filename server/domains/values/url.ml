include Morph.SealHom (struct
    type t = string [@@deriving eq, show { with_path = false }]

    let field = "link"
    let validate = Validator.url
  end)
