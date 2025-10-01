type _ Effect.t +=
  | Get_conn : (module Rapper_helper.CONNECTION) Effect.t
  | Transaction : (module Rapper_helper.CONNECTION) Effect.t
