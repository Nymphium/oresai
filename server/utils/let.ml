module Option = struct
  include Core.Option

  let ( let* ) = ( >>= )
end

module Result = struct
  include Core.Result

  let ( let* ) = ( >>= )
end
