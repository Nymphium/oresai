open Core

module Iso (M : sig
    type t [@@deriving eq]
  end) : sig
  type t [@@deriving eq]

  val from : M.t -> t
  val to_ : t -> M.t
end = struct
  type t = M.t [@@deriving eq]

  let from = Fun.id
  let to_ = Fun.id
end

module Hom (M : sig
    type t [@@deriving eq]

    val validator : t Utils.Validator.t
  end) : sig
  type t [@@deriving eq]

  val from : M.t -> (t, Errors.t) Result.t
  val to_ : t -> M.t
end = struct
  type t = M.t [@@deriving eq]

  let from v =
    if M.validator.validate v
    then Ok v
    else Error (Errors.ConvertError (M.validator.report v))
  ;;

  let to_ = Fun.id
end
