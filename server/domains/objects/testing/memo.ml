module T = Domains.Objects.Memo
open T

let t = (module T : Alcotest.TESTABLE with type t = T.t)

let fixture
      ?(id = 0L)
      ?(user_id = 0L)
      ?(content = "content")
      ?(tags = [])
      ?(state = State.Public)
      ()
  =
  let id = Id.from id in
  let user_id = UserId.from user_id in
  let content = Content.unsafe_from content in
  let created_at = CreatedAt.from 0. in
  let updated_at = UpdatedAt.from 0. in
  make ~id ~user_id ~content ~tags ~state ~created_at ~updated_at ()
;;

let omit_id memo = { memo with id = Id.from 0L }

let omit_ts memo =
  { memo with created_at = CreatedAt.from 0.; updated_at = UpdatedAt.from 0. }
;;
