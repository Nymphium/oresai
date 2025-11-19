open Effect
open Deep

type _ action = ..

type _ Effect.t +=
  | Inject : (('a, [> Errors.t ]) Result.t as 'action) action -> 'action Effect.t

let o x = Effect.perform (Inject x)
let run action = o action

let%test_unit _ =
  let open Core in
  let module M = struct
    type _ action +=
      | U : (int, [> Errors.t ]) Result.t action
      | V : (int, [> Errors.t ]) Result.t action
  end
  in
  [%test_eq: int]
    3
    (let comp () =
       let open Let.Result in
       let* u = run M.U in
       let* v = run M.V in
       return (u + v)
     in
     match comp () with
     | effect Inject M.U, k -> continue k (Ok 1)
     | effect Inject M.V, k -> continue k (Ok 2)
     | Ok i -> i
     | Error _ -> -1)
;;
