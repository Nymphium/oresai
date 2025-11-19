open struct
  module M = Objects.User
end

open Locator

type _ action +=
  | Create :
      { name : M.Name.t
      ; email : M.Email.t
      ; display_name : M.DisplayName.t
      ; bio : M.Bio.t
      ; avatar_url : M.AvatarUrl.t option
      ; password : Values.Password.t
      ; links : M.Links.t
      }
      -> (M.t, [> Errors.t ]) Result.t action
  | FindByEmail : { email : string } -> (M.t Option.t, [> Errors.t ]) Result.t action
  | FindById : { user_id : int64 } -> (M.t Option.t, [> Errors.t ]) Result.t action
  | CheckPassword :
      { user_id : M.Id.t
      ; password : string
      }
      -> (bool, [> Errors.t ]) Result.t action
  | Update :
      { user_id : M.Id.t
      ; name : M.Name.t option
      ; display_name : M.DisplayName.t option
      ; bio : M.Bio.t option
      ; avatar_url : M.AvatarUrl.t option
      ; links : M.Links.t option
      }
      -> (M.t, [> Errors.t ]) Result.t action
