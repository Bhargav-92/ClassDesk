-- Keep existing full names intact; their first/last-name boundaries may be ambiguous.
ALTER TABLE "students" RENAME COLUMN "name" TO "first_name";
--> statement-breakpoint
ALTER TABLE "students" RENAME COLUMN "parent_name" TO "parent_first_name";
--> statement-breakpoint
ALTER TABLE "students" ADD COLUMN "last_name" text;
--> statement-breakpoint
UPDATE "students" SET "last_name" = '';
--> statement-breakpoint
ALTER TABLE "students" ALTER COLUMN "last_name" SET NOT NULL;
--> statement-breakpoint
ALTER TABLE "students" ADD COLUMN "parent_last_name" text;
