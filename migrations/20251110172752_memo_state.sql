-- Modify "memos" table
ALTER TABLE "public"."memos" DROP COLUMN "is_public", ADD COLUMN "satate" "public"."memo_state" NOT NULL;
