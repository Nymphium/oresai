let string ?(min = 0) ?max ?regexp s =
  let len = String.length s in
  let open Let.Option in
  let pass_min = len >= min in
  let pass_max =
    Option.value ~default:true
    @@
    let* max = max in
    return (len <= max)
  in
  let pass_regexp =
    Option.value ~default:true
    @@
    let* regexp = regexp in
    let rex = Pcre.regexp regexp in
    return @@ Pcre.pmatch ~rex s
  in
  pass_min && pass_max && pass_regexp
;;

let url s = string s ~regexp:{|^(https?://)?([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(/.*)?$|}

let%test_module "string" =
  (module struct
    let%test "nosettings" =
      let sv = string in
      sv "abc"
    ;;

    let%test "min" =
      let sv = string ~min:3 in
      sv "abc"
    ;;

    let%test "max" =
      let sv = string ~max:3 in
      sv "abc"
    ;;

    let%test "regexp" =
      let sv = string ~regexp:{|\w+|} in
      sv "abc"
    ;;

    let%test "comp" =
      let sv = string ~min:3 ~max:5 ~regexp:{|[a-z]+|} in
      sv "abc"
    ;;

    let%test "url" =
      let sv = url in
      sv "https://example.com"
    ;;
  end)
;;

let list ~element ?(min = 0) ?max lst =
  let len = List.length lst in
  let open Let.Option in
  let pass_min = len >= min in
  let pass_max =
    Option.value ~default:true
    @@
    let* max = max in
    return (len <= max)
  in
  let pass_elements = List.for_all element lst in
  pass_min && pass_max && pass_elements
;;

let%test_module "list" =
  (module struct
    let element = string ~min:1 ~max:10

    let%test "nosettings" =
      let lv = list ~element in
      lv [ "abc"; "def" ]
    ;;

    let%test "min" =
      let lv = list ~element ~min:1 in
      lv [ "abc"; "def" ]
    ;;

    let%test "max" =
      let lv = list ~element ~max:3 in
      lv [ "abc"; "def" ]
    ;;

    let%test "comp" =
      let lv = list ~element ~min:1 ~max:3 in
      lv [ "abc"; "def" ]
    ;;
  end)
;;
