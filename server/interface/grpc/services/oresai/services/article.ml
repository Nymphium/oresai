open Core

open struct
  module Bwd = struct
    module File = Protos.Oresai_services_article
    module Service = File.Oresai.Services.ArticleService
    module O = Protos.Oresai_objects_article.Oresai.Objects
    module Tag = Protos.Oresai_objects_tag.Oresai.Objects.Tag
  end

  let create (m : (module Utils.UC)) =
    let module Rpc = Bwd.Service.CreateArticle in
    let module G = Utils.Grpc ((val m)) in
    G.create_unary_handler (module Rpc) @@ fun { user_id; title; content; tags; state } ->
    let open Let.Result in
    let* _user = Usecases.Get_user_by_id.run ~user_id in
    let state = Bwd.O.ArticleState.to_string state in
    let* article =
      Usecases.User_create_article.run
        ~user_id
        ~title
        ~content
        ~tag_ids:(List.map tags ~f:(fun t -> t.id))
        ~state
        ()
    in
    return
    @@ Rpc.Response.make
         ~id:(Domains.Objects.Article.id article)
         ~title:(Domains.Objects.Article.title article)
         ~content:(Domains.Objects.Article.content article)
         ~user_id:(Domains.Objects.Article.user_id article)
         ~tags:
           (List.map (Domains.Objects.Article.tags article) ~f:(fun tag ->
              Bwd.Tag.make
                ~id:(Domains.Objects.Tag.id tag)
                ~name:(Domains.Objects.Tag.name tag)
                ()))
         ~state:
           (match Domains.Objects.Article.(article.state) with
            | Domains.Objects.Article.State.Draft ->
              Bwd.O.ArticleState.ARTICLE_STATE_DRAFT
            | Domains.Objects.Article.State.Published ->
              Bwd.O.ArticleState.ARTICLE_STATE_PUBLISHED_PUBLIC
            | Domains.Objects.Article.State.Archived ->
              Bwd.O.ArticleState.ARTICLE_STATE_PUBLISHED_PRIVATE)
         (* ~created_at:(Domains.Objects.Article.created_at article |> Float.to_string) *)
         (* ~updated_at:(Domains.Objects.Article.updated_at article |> Float.to_string) *)
         ()
  ;;

  let service m = Grpc_eio.Server.Service.(v () |> create m |> handle_request)
end

let register m =
  Grpc_eio.Server.add_service ~name:Bwd.Service.package_service_name ~service:(service m)
;;
