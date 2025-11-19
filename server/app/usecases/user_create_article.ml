(* tag_ids are validated in the repository layer *)
let run ~user_id ~title ~content ~tag_ids ~state () =
  let open Let.Result in
  let open Domains.Objects in
  let user_id = User.Id.from user_id in
  let* title = Article.Title.from title in
  let* content = Article.Content.from content in
  let* state = Article.State.from state in
  Domains.Repositories.(
    Locator.run @@ Article.Create { title; content; user_id; tag_ids; state })
;;
