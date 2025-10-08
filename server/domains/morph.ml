module type Sealed = sig
  type bwd [@@deriving eq, show]
  type t [@@deriving eq, show]

  val from : bwd -> t
  val to_ : t -> bwd
end

module type SealedHom = sig
  type bwd [@@deriving eq, show]
  type t [@@deriving eq, show]

  val validate : bwd -> bool
  val to_ : t -> bwd
  val from : bwd -> (t, [> Errors.t ]) Result.t

  (** [unsafe_from] converts as if by isomorphism, which is dangerous. Use it
      only when the conversion is valid. *)
  val unsafe_from : bwd -> t
end

module Seal (M : sig
    type t [@@deriving eq, show]
  end) : Sealed with type bwd = M.t = struct
  include M

  type bwd = t [@@deriving eq, show { with_path = false }]

  let from = Fun.id
  let to_ = Fun.id
end

module SealHom (M : sig
    type t [@@deriving eq, show]

    val validate : t -> bool
    val field : string
  end) : SealedHom with type bwd = M.t = struct
  include M

  type bwd = t [@@deriving eq, show { with_path = false }]

  let to_ = Fun.id
  let unsafe_from = Fun.id
  let[@inline] from t = if validate t then Ok t else Error (`ConvertError field)
end
