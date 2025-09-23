module Iso (Fwd : sig
    module M : Domains.Objects.Morph.Sealed

    val typ : M.bwd Caqti_type.t
  end) : Rapper.CUSTOM with type t = Fwd.M.t = struct
  type t = Fwd.M.t

  let t =
    let encode = Fun.compose Result.ok Fwd.M.to_ in
    let decode = Fun.compose Result.ok Fwd.M.from in
    Caqti_type.(custom ~encode ~decode Fwd.typ)
  ;;
end

module Hom (Fwd : sig
    module M : Domains.Objects.Morph.SealedHom

    val typ : M.bwd Caqti_type.t
  end) : Rapper.CUSTOM with type t = Fwd.M.t = struct
  type t = Fwd.M.t

  let t =
    let encode = Fun.compose Result.ok Fwd.M.to_ in
    let decode s = Fwd.M.from s |> Result.map_error @@ fun (`ConvertError p) -> p in
    Caqti_type.(custom ~encode ~decode Fwd.typ)
  ;;
end
