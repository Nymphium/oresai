table "articles" {
  schema = schema.public
  column "id" {
    type = bigint
    identity {
      generated = "BY_DEFAULT"
    }
    null = false
  }
  column "user_id" {
    type = bigint
    null = false
  }
  column "title" {
    type = varchar(255)
    null = false
  }
  column "content" {
    type = text
    null = false
  }
  column "state" {
    type = enum.article_state
    null = false
  }
  column "created_at" {
    type    = timestamptz
    default = sql("now()")
    null    = false
  }
  column "updated_at" {
    type    = timestamptz
    default = sql("now()")
    null    = false
  }
  primary_key {
    columns = [column.id]
  }
  foreign_key "articles_user_id_fkey" {
    columns     = [column.user_id]
    ref_columns = [table.users.column.id]
  }
}

table "articles_tags" {
  schema = schema.public
  column "article_id" {
    type = bigint
    null = false
  }
  column "tag_id" {
    type = bigint
    null = false
  }
  primary_key {
    columns = [column.article_id, column.tag_id]
  }
  foreign_key "articles_tags_article_id_fkey" {
    columns     = [column.article_id]
    ref_columns = [table.articles.column.id]
  }
  foreign_key "articles_tags_tag_id_fkey" {
    columns     = [column.tag_id]
    ref_columns = [table.tags.column.id]
  }
}

enum "article_state" {
  schema = schema.public
  values = ["published_public", "published_private", "draft"]
}
