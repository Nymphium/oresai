table "users" {
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
  column "email" {
    type = varchar(255)
    null = false
  }
  column "display_name" {
    type = varchar(255)
    null = false
  }
  column "bio" {
    type = text
    null = false
  }
  column "avatar_url" {
    type = varchar(255)
    null = false
  }
  column "created_at" {
    type    = timestamptz
    default = sql("now()")
    null    = false
  }
  column "user_state" {
    type = enum.user_state
    null = false
  }
  primary_key {
    columns = [column.id]
  }
  index "users_name_key" {
    unique  = true
    columns = [column.name]
  }
  index "users_email_key" {
    unique  = true
    columns = [column.email]
  }
}

table "users_links" {
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
  column "url" {
    type = varchar(255)
    null = false
  }
  primary_key {
    columns = [column.id]
  }
  foreign_key "users_links_user_id_fkey" {
    columns     = [column.user_id]
    ref_columns = [table.users.column.id]
  }
}

enum "user_state" {
  schema = schema.public
  values = ["public", "private"]
}

