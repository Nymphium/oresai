open Core
module T = Domains.Objects.User
open T

let t = (module T : Alcotest.TESTABLE with type t = T.t)

let fixture
      ?(id = 0L)
      ?(name = "Testing Oresai")
      ?(email = "test@example.invalid")
      ?(display_name = "test")
      ?(bio = "")
      ?avatar_url
      ?(links = [])
      ()
  =
  let name = Name.unsafe_from name in
  let email = Email.unsafe_from email in
  let display_name = DisplayName.unsafe_from display_name in
  let bio = Bio.unsafe_from bio in
  let avatar_url = Option.map ~f:AvatarUrl.unsafe_from avatar_url in
  let links = List.map ~f:Links.Element.unsafe_from links in
  let id = Id.from id in
  let created_at = CreatedAt.from 0. in
  make ~id ~name ~email ~display_name ~bio ?avatar_url ~links ~created_at ()
;;

let omit_id user = { user with id = Id.from 0L }
let omit_ts user = { user with created_at = CreatedAt.from 0. }
