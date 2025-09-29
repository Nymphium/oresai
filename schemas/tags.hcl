table "tags" {
  schema = schema.public
  column "id" {
    type = bigint
    identity {
      generated = "BY_DEFAULT"
    }
    null = false
  }
  column "name" {
    type = varchar(255)
    null = false
  }
  column "user_id" {
    type = bigint
    null = false
  }
  primary_key {
    columns = [column.id]
  }
  foreign_key "tags_user_id_fkey" {
    columns     = [column.user_id]
    ref_columns = [table.users.column.id]
  }
  index "tags_user_id_name_key" {
    unique  = true
    columns = [column.user_id, column.name]
  }
}
