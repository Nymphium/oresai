(** Provides JSON format, Logs reporter with non-blocking eio *)

let reporter ~sw ~env ~stdout =
  let clock = Eio.Stdenv.clock env in
  let tz_offset_s = Ptime_clock.current_tz_offset_s () in
  let pp_now f t = Ptime.pp_rfc3339 ?tz_offset_s () f t in
  let escape s =
    s
    |> Pcre.replace ~pat:{|"|} ~templ:{|\"|}
    |> Pcre.replace ~pat:{|\n|} ~templ:{|\\n|}
    |> String.trim
  in
  let pp_tags_json_like ppf = function
    | None -> ()
    | Some tags ->
      let bindings =
        Logs.Tag.fold
          (fun (Logs.Tag.V (tag, value)) acc ->
             let () = Eio.Fiber.yield () in
             let key = Logs.Tag.name tag in
             let value_str =
               Format.asprintf "%a" (Logs.Tag.printer tag) value |> escape
             in
             (key, value_str) :: acc)
          tags
          []
      in
      let pp_sep ppf () = Format.fprintf ppf ",@ " in
      let pp_binding ppf (key, value) =
        Format.fprintf ppf {|@[<h>"%s":@ "%s"@]|} key value
      in
      Format.fprintf
        ppf
        ",@ %a"
        (Format.pp_print_list ~pp_sep pp_binding)
        (List.rev bindings)
  in
  let report (type a b) src level ~over (k : unit -> b) (msgf : (a, b) Logs.msgf) : b =
    let res = Atomic.make None in
    let k () =
      match Atomic.get res with
      | Some v -> v
      | None ->
        let v = k () in
        Atomic.set res (Some v);
        v
    in
    k
    @@ Eio.Fiber.fork ~sw
    @@ fun () ->
    ignore
    @@ msgf
    @@ fun ?header:_ ?tags fmt ->
    let now =
      Eio.Time.now clock |> Ptime.of_float_s |> Option.value ~default:Ptime.epoch
    in
    let buf = Buffer.create 256 in
    let ppf = Format.formatter_of_buffer buf in
    Format.kasprintf
      (fun msg ->
         let msg = msg |> escape in
         let () =
           Format.fprintf
             ppf
             {j|@[<h>{@ "src":@ "%s",@ "log_level":@ "%a",@ "timestamp":@ "%a",@ "message":@ "%s"%a@ }@]@.|j}
             (Logs.Src.name src |> escape)
             Logs.pp_level
             level
             pp_now
             now
             msg
             pp_tags_json_like
             tags
         in
         Eio.Flow.copy_string (Buffer.contents buf) stdout;
         over () |> k)
      fmt
  in
  { Logs.report }
;;

module Level = struct
  type t = Logs.level [@@deriving show]

  let reader =
    Oenv.(Fun.compose (default Logs.Info) optional)
    @@ Fun.flip (Oenv.custom ~secret:false) "LOG_LEVEL"
    @@ fun s ->
    match String.lowercase_ascii s with
    | "debug" -> Ok Logs.Debug
    | "info" -> Ok Logs.Info
    | "warning" -> Ok Logs.Warning
    | "error" -> Ok Logs.Error
    | "app" -> Ok Logs.App
    | s -> Error (`Parse ("invalid log level", s))
  ;;
end

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
  let stdout = Eio.Stdenv.stdout env in
  let timer = Eio.Stdenv.clock env in
  Logs.set_reporter (reporter ~sw ~env ~stdout);
  Logs.(set_level @@ Some Debug);
  Logs.debug (fun m -> m "hello");
  Eio.Time.sleep timer 0.1;
  Logs.debug (fun m -> m {|"world"|});
  Eio.Time.sleep timer 0.1;
  [%expect
    {|
    { "src": "application", "log_level": "DEBUG", "timestamp": "2025-10-04T07:58:27+09:00", "message": "hello" }
    { "src": "application", "log_level": "DEBUG", "timestamp": "2025-10-04T07:58:27+09:00", "message": "\"world\"" }
    |}];
  Logs.debug (fun m ->
    let tags =
      Logs.Tag.(
        empty
        |> add (def "tag1" Format.pp_print_string) {|this is "tag1"|}
        |> add (def "tag2" Format.pp_print_int) 42)
    in
    m ~tags "");
  Eio.Time.sleep timer 0.1;
  [%expect
    {| { "src": "application", "log_level": "DEBUG", "timestamp": "2025-10-04T07:58:27+09:00", "message": "", "tag1": "this is \"tag1\"", "tag2": "42" } |}];
  Logs.debug (fun m ->
    m
      {|
      a
      b
      c
      |});
  Eio.Time.sleep timer 0.1;
  [%expect
    {| { "src": "application", "log_level": "DEBUG", "timestamp": "2025-10-04T07:58:27+09:00", "message": "\\n      a\\n      b\\n      c\\n" } |}]
;;
