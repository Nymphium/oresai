module type Sealed = sig
  type bwd
  type t [@@deriving eq]

  val from : bwd -> t
  val to_ : t -> bwd
end

module type SealedHom = sig
  type bwd
  type t [@@deriving eq]

  val validate : bwd -> bool
  val to_ : t -> bwd
  val from : bwd -> (t, Errors.t) Result.t
  val unsafe_from : bwd -> t
end

module Seal (M : sig
    type t [@@deriving eq]
  end) : Sealed with type bwd = M.t = struct
  include M

  type bwd = t

  let from = Fun.id
  let to_ = Fun.id
end

module SealHom (M : sig
    type t [@@deriving eq]

    val validate : t -> bool
    val field : string
  end) : SealedHom with type bwd = M.t = struct
  include M

  type bwd = t

  let to_ = Fun.id
  let unsafe_from = Fun.id
  let[@inline] from t = if validate t then Ok t else Error (`ConvertError field)
end
