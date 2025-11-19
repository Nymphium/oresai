module T = Domains.Objects.Tag
open T

let t = (module T : Alcotest.TESTABLE with type t = T.t)

let fixture ?(id = 0L) ?(name = "test") ?(user_id = 0L) () =
  let id = Id.from id in
  let name = Name.unsafe_from name in
  let user_id = Domains.Objects.User.Id.from user_id in
  make ~id ~name ~user_id
;;

let omit_id tag = { tag with id = Id.from 0L }
