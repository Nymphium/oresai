module type M = sig
  val register
    :  ([< Eio.Net.Sockaddr.t ] as 'a)
    -> H2.Reqd.t
    -> ('a -> H2.Reqd.t -> 'b)
    -> 'b
end

let v stream reqd l = l stream reqd
let ( +> ) l r stream reqd = l stream reqd r
