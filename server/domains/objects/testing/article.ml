module T = Domains.Objects.Article
open T

let t = (module T : Alcotest.TESTABLE with type t = T.t)

let fixture
      ?(id = 0L)
      ?(user_id = 0L)
      ?(title = "title")
      ?(content = "content")
      ?(tags = [])
      ?(state = State.Draft)
      ()
  =
  let id = Id.from id in
  let user_id = UserId.from user_id in
  let title = Title.unsafe_from title in
  let content = Content.unsafe_from content in
  (* let tags = List.map ~f:TagId.from tags in *)
  let created_at = CreatedAt.from 0. in
  let updated_at = UpdatedAt.from 0. in
  make ~id ~user_id ~title ~content ~tags ~state ~created_at ~updated_at ()
;;

let omit_id article = { article with id = Id.from 0L }

let omit_ts article =
  { article with created_at = CreatedAt.from 0.; updated_at = UpdatedAt.from 0. }
;;
