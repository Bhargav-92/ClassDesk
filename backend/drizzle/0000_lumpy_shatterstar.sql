CREATE TYPE "public"."attendance_status" AS ENUM('present', 'absent', 'late');--> statement-breakpoint
CREATE TYPE "public"."homework_status" AS ENUM('pending', 'submitted', 'checked');--> statement-breakpoint
CREATE TABLE "attendance" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"student_id" uuid NOT NULL,
	"class_date" date NOT NULL,
	"status" "attendance_status" NOT NULL
);
--> statement-breakpoint
CREATE TABLE "fee_payments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"monthly_fee_id" uuid NOT NULL,
	"fess_amount" integer NOT NULL,
	"paid_on" date NOT NULL,
	"recorded_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "fee_payments_amount_paise_check" CHECK ("fee_payments"."fess_amount" > 0)
);
--> statement-breakpoint
CREATE TABLE "homework" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"title" text NOT NULL,
	"instructions" text NOT NULL,
	"due_on" date,
	"attachment_url" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid NOT NULL
);
--> statement-breakpoint
CREATE TABLE "homework_submissions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"homework_id" uuid NOT NULL,
	"student_id" uuid NOT NULL,
	"status" "homework_status" DEFAULT 'pending' NOT NULL,
	"submitted_at" timestamp with time zone,
	"checked_at" timestamp with time zone,
	"teacher_feedback" text
);
--> statement-breakpoint
CREATE TABLE "monthly_fees" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"student_id" uuid NOT NULL,
	"billing_month" date NOT NULL,
	"fees_amount" integer NOT NULL,
	"due_on" date NOT NULL,
	"promised_payment_on" date,
	CONSTRAINT "monthly_fees_amount_paise_check" CHECK ("monthly_fees"."fees_amount" >= 0)
);
--> statement-breakpoint
CREATE TABLE "students" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"parent_name" text,
	"parent_whatsapp" text,
	"joined_on" date NOT NULL,
	"monthly_fee" integer NOT NULL,
	"fee_due_day" integer NOT NULL,
	CONSTRAINT "students_monthly_fee_check" CHECK ("students"."monthly_fee" >= 0),
	CONSTRAINT "students_fee_due_day_check" CHECK ("students"."fee_due_day" between 1 and 31)
);
--> statement-breakpoint
CREATE TABLE "users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"email" text NOT NULL,
	"password_hash" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "attendance" ADD CONSTRAINT "attendance_student_id_students_id_fk" FOREIGN KEY ("student_id") REFERENCES "public"."students"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fee_payments" ADD CONSTRAINT "fee_payments_monthly_fee_id_monthly_fees_id_fk" FOREIGN KEY ("monthly_fee_id") REFERENCES "public"."monthly_fees"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "homework" ADD CONSTRAINT "homework_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "homework_submissions" ADD CONSTRAINT "homework_submissions_homework_id_homework_id_fk" FOREIGN KEY ("homework_id") REFERENCES "public"."homework"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "homework_submissions" ADD CONSTRAINT "homework_submissions_student_id_students_id_fk" FOREIGN KEY ("student_id") REFERENCES "public"."students"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "monthly_fees" ADD CONSTRAINT "monthly_fees_student_id_students_id_fk" FOREIGN KEY ("student_id") REFERENCES "public"."students"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "attendance_student_date_unique" ON "attendance" USING btree ("student_id","class_date");--> statement-breakpoint
CREATE INDEX "attendance_class_date_idx" ON "attendance" USING btree ("class_date");--> statement-breakpoint
CREATE INDEX "fee_payments_monthly_fee_id_idx" ON "fee_payments" USING btree ("monthly_fee_id");--> statement-breakpoint
CREATE UNIQUE INDEX "homework_submissions_homework_student_unique" ON "homework_submissions" USING btree ("homework_id","student_id");--> statement-breakpoint
CREATE UNIQUE INDEX "monthly_fees_student_month_unique" ON "monthly_fees" USING btree ("student_id","billing_month");--> statement-breakpoint
CREATE INDEX "monthly_fees_billing_month_idx" ON "monthly_fees" USING btree ("billing_month");--> statement-breakpoint
CREATE UNIQUE INDEX "user_email_unique" ON "users" USING btree (lower("email"));