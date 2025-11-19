module type S = sig
  type err

  val run : (unit -> 'a) -> ('a, err) Result.t
end
