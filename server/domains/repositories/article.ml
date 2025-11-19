open struct
  module M = Objects.Article
end

open Locator

type _ action +=
  | Create :
      { user_id : M.UserId.t
      ; title : M.Title.t
      ; tag_ids : int64 list
      ; content : M.Content.t
      ; state : M.State.t
      }
      -> (M.t, [> Errors.t ]) Result.t action
  | ListByUser : { user_id : M.UserId.t } -> (M.t list, [> Errors.t ]) Result.t action
