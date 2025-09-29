table "memos" {
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
  column "content" {
    type = text
    null = false
  }
  column "is_public" {
    type = enum.memo_state
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
  foreign_key "memos_user_id_fkey" {
    columns     = [column.user_id]
    ref_columns = [table.users.column.id]
  }
}

table "memo_tags" {
  schema = schema.public
  column "memo_id" {
    type = bigint
    null = false
  }
  column "tag_id" {
    type = bigint
    null = false
  }
  primary_key {
    columns = [column.memo_id, column.tag_id]
  }
  foreign_key "memo_tags_memo_id_fkey" {
    columns     = [column.memo_id]
    ref_columns = [table.memos.column.id]
  }
  foreign_key "memo_tags_tag_id_fkey" {
    columns     = [column.tag_id]
    ref_columns = [table.tags.column.id]
  }
}
enum "memo_state" {
  schema = schema.public
  values = ["public", "private"]
}

