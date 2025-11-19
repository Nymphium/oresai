table "comments" {
  schema = schema.public
  column "id" {
    type = bigint
    identity {
      generated = "BY_DEFAULT"
    }
  }
  column "target_id" {
    type = bigint
  }
  column "target_type" {
    type = enum.comment_target_type
  }
  column "user_id" {
    type = bigint
  }
  column "content" {
    type = text
  }
  column "created_at" {
    type    = timestamptz
    default = sql("now()")
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
