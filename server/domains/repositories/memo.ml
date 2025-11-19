open struct
  module M = Objects.Memo
end

open Locator

type _ action +=
  | Create :
      { content : M.Content.t
      ; user_id : M.UserId.t
      ; tag_ids : M.TagId.t list
      ; state : M.State.t
      }
      -> (M.t, [> Errors.t ]) Result.t action
  | ListByUser : { user_id : M.UserId.t } -> (M.t list, [> Errors.t ]) Result.t action
