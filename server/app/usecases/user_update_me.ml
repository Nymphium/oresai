open Core

let run ~user_id ?name ?display_name ?bio ?avatar_url ~links () =
  let open Let.Result in
  let open Domains.Objects in
  let user_id = User.Id.from user_id in
  let* name =
    Option.fold
      name
      ~f:Fun.(const @@ compose (map ~f:Option.some) User.Name.from)
      ~init:(Ok None)
  in
  let* display_name =
    Option.fold
      display_name
      ~f:Fun.(const @@ compose (map ~f:Option.some) User.DisplayName.from)
      ~init:(Ok None)
  in
  let* bio =
    Option.fold
      bio
      ~f:Fun.(const @@ compose (map ~f:Option.some) User.Bio.from)
      ~init:(Ok None)
  in
  let* avatar_url =
    Option.fold
      avatar_url
      ~f:Fun.(const @@ compose (map ~f:Option.some) User.AvatarUrl.from)
      ~init:(Ok None)
  in
  let* links = User.Links.from links |> map ~f:Option.some in
  Domains.Repositories.(
    Locator.run @@ User.Update { user_id; name; display_name; bio; avatar_url; links })
;;
