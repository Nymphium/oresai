open Core

let register ~env stream reqd k =
  let clock = Eio.Stdenv.clock env in
  let H2.Request.{ headers; _ } = H2.Reqd.request reqd in
  let auth = H2.Headers.get headers "authorization" in
  match auth with
  | Some auth ->
    if String.is_prefix auth ~prefix:"Bearer "
    then (
      (* entire length - |Bearer | *)
      let token = String.sub auth ~pos:7 ~len:(String.length auth - 7) in
      Usecases.Get_user_id_from_access_token.run ~clock token |> function
      | Ok user_id ->
        let user_id = Domains.Objects.User.Id.from user_id in
        Eio.Fiber.with_binding Context.user_id user_id @@ fun () -> k stream reqd
      | Error err ->
        Logs.err (fun m ->
          m
            ~tags:Logs.Tag.(empty |> add (def "error" Errors.pp) err)
            "Failed to get user id from access token"))
    else Logs.warn (fun m -> m "Authorization header is not a Bearer token");
    k stream reqd
  | None -> k stream reqd
;;
