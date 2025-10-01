-- Modify "users" table
ALTER TABLE "public"."users" ADD COLUMN "hashed_password" text NOT NULL;
