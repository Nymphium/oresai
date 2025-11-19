open Core

module Iso (Fwd : sig
    module M : Domains.Morph.Sealed

    val typ : M.bwd Caqti_type.t
  end) : Rapper.CUSTOM with type t = Fwd.M.t = struct
  type t = Fwd.M.t

  let t =
    let encode = Fun.compose Result.return Fwd.M.to_ in
    let decode = Fun.compose Result.return Fwd.M.from in
    Caqti_type.(custom ~encode ~decode Fwd.typ)
  ;;
end

module Hom (Fwd : sig
    module M : Domains.Morph.SealedHom

    val typ : M.bwd Caqti_type.t
  end) : Rapper.CUSTOM with type t = Fwd.M.t = struct
  type t = Fwd.M.t

  let t =
    let encode = Fun.compose Result.return Fwd.M.to_ in
    let decode s = Fwd.M.from s |> Result.map_error ~f:Domains.Errors.show in
    Caqti_type.(custom ~encode ~decode Fwd.typ)
  ;;
end
