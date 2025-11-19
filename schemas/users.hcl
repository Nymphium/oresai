table "users" {
  schema = schema.public
  column "id" {
    type = bigint
    identity {
      generated = "BY_DEFAULT"
    }
  }
  column "name" {
    type = varchar(255)
  }
  column "email" {
    type = varchar(255)
  }
  column "display_name" {
    type = varchar(255)
  }
  column "bio" {
    type = text
  }
  column "avatar_url" {
    type = varchar(255)
    null = true
  }
  column "hashed_password" {
    type = text
  }
  column "created_at" {
    type    = timestamptz
    default = sql("now()")
  }
  primary_key {
    columns = [column.id]
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
  }
  column "user_id" {
    type = bigint
  }
  column "url" {
    type = varchar(255)
  }
  primary_key {
    columns = [column.id]
  }
  foreign_key "users_links_user_id_fkey" {
    columns     = [column.user_id]
    ref_columns = [table.users.column.id]
  }
}
