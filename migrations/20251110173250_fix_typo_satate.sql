-- Modify "memos" table
ALTER TABLE "public"."memos" DROP COLUMN "satate", ADD COLUMN "state" "public"."memo_state" NOT NULL;
