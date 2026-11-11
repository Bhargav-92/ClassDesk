ALTER TABLE "students" ADD COLUMN "fee_due_date" date;
--> statement-breakpoint
-- Map each legacy day to its first due date on/after joining.
WITH months AS (
 SELECT "id", "fee_due_day", "joined_on",
   (date_trunc('month', "joined_on") + CASE WHEN "fee_due_day" < extract(day FROM "joined_on") THEN interval '1 month' ELSE interval '0 months' END)::date AS month_start
 FROM "students"
)
UPDATE "students" AS s
SET "fee_due_date" = months.month_start + (least(months.fee_due_day, extract(day FROM (months.month_start + interval '1 month - 1 day'))::integer) - 1)
FROM months WHERE s.id = months.id;
--> statement-breakpoint
ALTER TABLE "students" ALTER COLUMN "fee_due_date" SET NOT NULL;
--> statement-breakpoint
ALTER TABLE "students" DROP CONSTRAINT "students_fee_due_day_check";
--> statement-breakpoint
ALTER TABLE "students" DROP COLUMN "fee_due_day";
