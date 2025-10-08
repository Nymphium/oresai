(** Provides JSON format, Logs reporter with non-blocking eio *)

let reporter ~sw ~env =
  let clock = Eio.Stdenv.clock env in
  let tz_offset_s = Ptime_clock.current_tz_offset_s () in
  (* let dq = Re.(compile @@ char '"') in *)
  let pp_tags_json_like ppf = function
    | None -> ()
    | Some tags ->
      let tags =
        let pp_now f t = Ptime.pp_rfc3339 ?tz_offset_s () f t in
        let now =
          Eio.Time.now clock |> Ptime.of_float_s |> Option.value ~default:Ptime.epoch
        in
        tags |> Logs.Tag.(add (def "timestamp" pp_now) now)
      in
      let bindings =
        Logs.Tag.fold
          (fun (Logs.Tag.V (tag, value)) acc ->
             let key = Logs.Tag.name tag in
             let value_str =
               Format.asprintf "%a" (Logs.Tag.printer tag) value
               |> Pcre.replace ~pat:{|"|} ~templ:{|\"|}
             in
             (key, value_str) :: acc)
          tags
          []
      in
      let pp_sep ppf () = Format.fprintf ppf ",@ " in
      let pp_binding ppf (key, value) = Format.fprintf ppf {|"%s":@ "%s"|} key value in
      Format.fprintf
        ppf
        " %a,@ "
        (Format.pp_print_list ~pp_sep pp_binding)
        (List.rev bindings)
  in
  let report (type a b) _src level ~over (k : unit -> b) (msgf : (a, b) Logs.msgf) : b =
    let res = Atomic.make None in
    let k () =
      match Atomic.get res with
      | Some v -> v
      | None ->
        let v = k () in
        Atomic.set res (Some v);
        v
    in
    let () =
      Eio.Fiber.fork ~sw @@ fun () ->
      ignore
      @@ msgf
      @@ fun ?header:_ ?tags fmt ->
      let f = Format.std_formatter in
      Format.kfprintf
        (fun f -> Format.pp_print_flush f () |> over |> k)
        f
        ({j|@[<h>{@ "log_level":@ "%a",@ %a"message":@ "|j} ^^ fmt ^^ {j|"@ }@]@.|j})
        Logs.pp_level
        level
        pp_tags_json_like
        tags
    in
    k ()
  in
  { Logs.report }
;;

module Expect_test_config = struct
  include Expect_test_config

  let sanitize s =
    s
    |> Pcre.replace
         ~pat:
           {|"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\+[0-9]{2}:[0-9]{2}|Z)"|}
         ~templ:{|"2025-10-04T07:58:27+09:00"|}
  ;;
end

let%expect_test _ =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  Logs.set_reporter (reporter ~sw ~env);
  Logs.(set_level @@ Some Debug);
  Logs.debug (fun m -> m "hello");
  Logs.debug (fun m -> m "world");
  [%expect
    {|
    { "log_level": "DEBUG", "message": "hello" }
    { "log_level": "DEBUG", "message": "world" }
    |}];
  Logs.debug (fun m ->
    let tags =
      Logs.Tag.(
        empty
        |> add (def "tag1" Format.pp_print_string) {|this is "tag1"|}
        |> add (def "tag2" Format.pp_print_int) 42)
    in
    m ~tags "");
  [%expect
    {| { "log_level": "DEBUG",  "tag1": "this is \"tag1\"", "tag2": "42", "timestamp": "2025-10-04T07:58:27+09:00", "message": "" } |}]
;;
