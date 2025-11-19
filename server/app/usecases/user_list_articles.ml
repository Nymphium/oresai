let run ~user_id () = Domains.Repositories.(Locator.run @@ Article.ListByUser { user_id })
