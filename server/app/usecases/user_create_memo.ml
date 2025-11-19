let run ~user_id ~content ~tag_ids ~state () =
  let open Let.Result in
  let open Domains.Objects in
  let user_id = User.Id.from user_id in
  let* content = Memo.Content.from content in
  let* state = Memo.State.from state in
  (* tag_ids are validated in the repository layer *)
  Domains.Repositories.(Locator.run @@ Memo.Create { content; user_id; tag_ids; state })
;;
