table "comments" {
  schema = schema.public
  column "id" {
    type = bigint
    identity {
      generated = "BY_DEFAULT"
    }
    null = false
  }
  column "target_id" {
    type = bigint
    null = false
  }
  column "target_type" {
    type = enum.comment_target_type
    null = false
  }
  column "user_id" {
    type = bigint
    null = false
  }
  column "content" {
    type = text
    null = false
  }
  column "created_at" {
    type    = timestamptz
    default = sql("now()")
    null    = false
  }
  primary_key {
    columns = [column.id]
  }
  foreign_key "comments_user_id_fkey" {
    columns     = [column.user_id]
    ref_columns = [table.users.column.id]
  }
}
enum "comment_target_type" {
  schema = schema.public
  values = ["articles", "memos"]
}
