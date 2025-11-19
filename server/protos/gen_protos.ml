let emit_bidings = Array.iter @@ fun mdl -> Printf.printf "module %s = %s\n" mdl mdl

let emit_reflection mdls =
  print_endline "let service_list =\n  let open Dynarray in\n  let v = create () in";
  Array.iter
    (fun mdl -> Printf.printf "  append_list v %s.Metainfo.package_service_names;\n" mdl)
    mdls;
  print_endline "  to_list v\n;;";
  print_newline ();
  print_endline "let fd_of_service = function";
  Array.iter
    (fun mdl ->
       Printf.printf
         "  | name when List.mem name %s.Metainfo.package_service_names -> Some \
          %s.Metainfo.file_descriptor_proto\n"
         mdl
         mdl)
    mdls;
  print_endline "  | _ -> None\n;;";
  print_newline ();
  print_endline "let fd_of_filename = function";
  Array.iter
    (fun mdl ->
       Printf.printf
         "  | name when name = %s.Metainfo.file_name -> Some \
          %s.Metainfo.file_descriptor_proto\n"
         mdl
         mdl)
    mdls;
  print_endline "  | _ -> None\n"
;;

let emit_error_module () =
  print_endline "module Errors = struct";
  print_endline "  open Ocaml_protoc_plugin.Result";
  print_endline "  type t = error";
  print_endline "  let pp = pp_error";
  print_endline "end";
  print_newline ()
;;

let () =
  let target_dir = "generated" in
  let mdls =
    Sys.readdir target_dir
    |> Array.map (Fun.compose String.capitalize_ascii Filename.chop_extension)
  in
  emit_error_module ();
  emit_bidings mdls;
  print_newline ();
  emit_reflection mdls
;;
