schema "public" {}

table "organizations" {
  schema = schema.public
  column "id" {
    null = false
    type = bigint
    identity {
      generated = "BY_DEFAULT"
    }
  }
  column "name" {
    null = false
    type = varchar(100)
  }
  column "created_at" {
    null    = false
    type    = timestamptz
    default = sql("now()")
  }
  primary_key {
    columns = [column.id]
  }
}

table "users" {
  schema = schema.public
  column "id" {
    null = false
    type = bigint
    identity {
      generated = "BY_DEFAULT"
    }
  }
  column "name" {
    null = false
    type = varchar(100)
  }
  column "email" {
    null = false
    type = varchar(255)
  }
  index "users_email_key" {
    unique  = true
    columns = [column.email]
  }
  column "created_at" {
    null    = false
    type    = timestamptz
    default = sql("now()")
  }
  primary_key {
    columns = [column.id]
  }
}

table "user_profiles" {
  schema = schema.public
  column "user_id" {
    null = false
    type = bigint
  }
  column "nickname" {
    null = false
    type = varchar(100)
  }
  column "profile" {
    null = false
    type = text
  }
  column "birth_date" {
    null = false
    type = timestamp
  }
  primary_key {
    columns = [column.user_id]
  }
  foreign_key "user_profiles_user_id_fk" {
    columns     = [column.user_id]
    ref_columns = [table.users.column.id]
    on_delete   = NO_ACTION
  }
}

table "documents" {
  schema = schema.public
  column "id" {
    null = false
    type = bigint
    identity {
      generated = "BY_DEFAULT"
    }
  }
  column "organization_id" {
    null = false
    type = bigint
  }
  column "title" {
    null = false
    type = varchar(255)
  }
  column "author_id" {
    null = false
    type = bigint
  }
  column "content" {
    null = false
    type = text
  }
  column "created_at" {
    null    = false
    type    = timestamptz
    default = sql("now()")
  }
  column "updated_at" {
    null    = false
    type    = timestamptz
    default = sql("now()")
  }
  primary_key {
    columns = [column.id]
  }
  foreign_key "documents_organization_id_fk" {
    columns     = [column.organization_id]
    ref_columns = [table.organizations.column.id]
    on_delete   = NO_ACTION
  }
  foreign_key "documents_author_id_fk" {
    columns     = [column.author_id]
    ref_columns = [table.users.column.id]
    on_delete   = NO_ACTION
  }
}
