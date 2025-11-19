let run ~name ~email ~password ~display_name ~bio ?avatar_url ~links () =
  let open Let.Result in
  let open Domains.Objects in
  let* name = User.Name.from name in
  let* email = User.Email.from email in
  let* password = Domains.Values.Password.from password in
  let* display_name = User.DisplayName.from display_name in
  let* bio = User.Bio.from bio in
  let* avatar_url =
    match avatar_url with
    | Some avatar_url ->
      let* url = User.AvatarUrl.from avatar_url in
      Ok (Some url)
    | None -> Ok None
  in
  let* links = User.Links.from links in
  Domains.Repositories.(
    Locator.run
    @@ User.Create { name; email; display_name; bio; avatar_url; password; links })
  >>| fun { id; _ } -> id
;;
