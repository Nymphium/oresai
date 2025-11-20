open Core
open Effect.Deep
open Domains.Repositories

open struct
  let system th =
    try th () with
    | effect Locator.Inject System.Ping, k -> continue k @@ Sql.System.ping ()
  ;;

  let users th =
    try th () with
    | effect
        Locator.Inject
          (User.Create { name; email; display_name; bio; avatar_url; password; links }), k
      ->
      continue k
      @@ Sql.Users.create
           ~name
           ~email
           ~display_name
           ~bio
           ?avatar_url
           ~hashed_password:password
           ~links
           ()
    | effect Locator.Inject (User.CheckPassword { user_id; password }), k ->
      continue k @@ Sql.Users.check_password user_id password
    | effect Locator.Inject (User.FindByEmail { email }), k ->
      continue k @@ Sql.Users.find_by_email email
    | effect Locator.Inject (User.FindById { user_id }), k ->
      continue k @@ Sql.Users.find_by_id user_id
    | effect
        Locator.Inject
          (User.Update { user_id; name; display_name; bio; avatar_url; links }), k ->
      continue k
      @@ Sql.Users.update user_id ?name ?display_name ?bio ?avatar_url ?links ()
  ;;

  let memos th =
    try th () with
    (* | effect Locator.Inject (Memo.Create { content; user_id; tag_ids; state }), k -> *)
    (*   continue k @@ Sql.Memos.create ~content ~user_id ~tag_ids ~state *)
    | effect Locator.Inject (Memo.ListByUser { user_id }), k ->
      continue k @@ Sql.Memos.list_by_user_id user_id
  ;;

  let articles th =
    try th () with
    (* | effect *)
    (*     Locator.Inject (Article.Create { title; content; user_id; tag_ids; state }), k -> *)
    (*   continue k @@ Sql.Articles.create ~title ~content ~user_id ~tag_ids ~state *)
    | effect Locator.Inject (Article.ListByUser { user_id }), k ->
      continue k @@ Sql.Articles.list_by_user_id user_id
  ;;
end

let v ~db th =
  (* let conn = Eio.Fiber.get Sql.Context.conn |> Option.value_exn in *)
  Sql.Handler.v db @@ fun () ->
  system @@ fun () ->
  articles @@ fun () ->
  memos @@ fun () -> users @@ th
;;
