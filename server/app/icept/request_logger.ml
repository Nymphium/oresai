let register stream reqd k =
  let H2.Request.{ target; _ } = H2.Reqd.request reqd in
  let () =
    Logs.info (fun m ->
      m
        ~tags:
          Logs.Tag.(
            empty
            |> add (def "ip_addr" Eio.Net.Sockaddr.pp) stream
            |> add (def "path" @@ fun f s -> Format.fprintf f "%s" s) target)
        "receive request")
  in
  k stream reqd
;;
