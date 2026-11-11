import { sql } from "drizzle-orm";
import {
  check,
  date,
  index,
  integer,
  pgEnum,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from "drizzle-orm/pg-core";

// ---------- Enums ----------

export const attendanceStatus = pgEnum("attendance_status", [
  "present",
  "absent",
  "late",
]);

export const homeworkStatus = pgEnum("homework_status", [
  "pending",
  "submitted",
  "checked",
]);

export const users = pgTable(
  "users",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    name: text("name").notNull(),
    email: text("email").notNull(),
    passwordHash: text("password_hash").notNull(),
    createdAt: timestamp("created_at", {
      withTimezone: true,
    })
      .defaultNow()
      .notNull(),
  },
  (table) => [
    uniqueIndex("user_email_unique").on(sql`lower(${table.email})`),
  ]
);

export const students = pgTable(
  "students",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    fname:text("first_name").notNull(),
    lname:text("last_name").notNull(),
    parentfName: text("parent_first_name"),
    parentlName: text("parent_last_name"),
    parentWhatsapp: text("parent_whatsapp"),
    joinedOn: date("joined_on", { mode: "string" }).notNull(),
    // Default monthly fee in paise. Must be zero or greater.
    monthlyFee: integer("monthly_fee").notNull(),
    // Day of month, 1 to 31.
    feeDueDay: integer("fee_due_day").notNull(),
  },
  (table) => [
    check(
      "students_monthly_fee_check",
      sql`${table.monthlyFee} >= 0`
    ),
    check(
      "students_fee_due_day_check",
      sql`${table.feeDueDay} between 1 and 31`
    ),
  ]
);

// ---------- Monthly fees ----------

export const monthlyFees = pgTable(
  "monthly_fees",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    studentId: uuid("student_id")
      .notNull()
      .references(() => students.id, { onDelete: "restrict" }),
    // First day of the billing month, e.g. 2026-09-01.
    billingMonth: date("billing_month", { mode: "string" }).notNull(),
    // Charged amount, preserved even if the student's default fee changes.
    feeAmount: integer("fees_amount").notNull(),
    dueOn: date("due_on", { mode: "string" }).notNull(),
    promisedPaymentOn: date("promised_payment_on", { mode: "string" }),
  },
  (table) => [
    uniqueIndex("monthly_fees_student_month_unique").on(
      table.studentId,
      table.billingMonth
    ),
    index("monthly_fees_billing_month_idx").on(table.billingMonth),
    check(
      "monthly_fees_amount_paise_check",
      sql`${table.feeAmount} >= 0`
    ),
  ]
);

// ---------- Fee payments (each full or partial payment) ----------

export const feePayments = pgTable(
  "fee_payments",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    monthlyFeeId: uuid("monthly_fee_id")
      .notNull()
      .references(() => monthlyFees.id, { onDelete: "restrict" }),
    feesAmount: integer("fess_amount").notNull(),
    paidOn: date("paid_on", { mode: "string" }).notNull(),
    recordedAt: timestamp("recorded_at", {
      withTimezone: true,
    })
      .defaultNow()
      .notNull(),
  },
  (table) => [
    index("fee_payments_monthly_fee_id_idx").on(table.monthlyFeeId),
    check(
      "fee_payments_amount_paise_check",
      sql`${table.feesAmount} > 0`
    ),
  ]
);

// ---------- Attendance ----------

export const attendance = pgTable(
  "attendance",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    studentId: uuid("student_id")
      .notNull()
      .references(() => students.id, { onDelete: "restrict" }),
    classDate: date("class_date", { mode: "string" }).notNull(),
    status: attendanceStatus("status").notNull(),
  },
  (table) => [
    uniqueIndex("attendance_student_date_unique").on(
      table.studentId,
      table.classDate
    ),
    index("attendance_class_date_idx").on(table.classDate),
  ]
);

// ---------- Homework (assignments apply to the whole class) ----------

export const homework = pgTable("homework", {
  id: uuid("id").defaultRandom().primaryKey(),
  title: text("title").notNull(),
  instructions: text("instructions").notNull(),
  dueOn: date("due_on", { mode: "string" }),
  attachmentUrl: text("attachment_url"),
  createdAt: timestamp("created_at", {
    withTimezone: true,
  })
    .defaultNow()
    .notNull(),
  createdBy: uuid("created_by")
    .notNull()
    .references(() => users.id, { onDelete: "restrict" }),
});

// ---------- Homework submissions ----------

export const homeworkSubmissions = pgTable(
  "homework_submissions",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    homeworkId: uuid("homework_id")
      .notNull()
      .references(() => homework.id, { onDelete: "restrict" }),
    studentId: uuid("student_id")
      .notNull()
      .references(() => students.id, { onDelete: "restrict" }),
    status: homeworkStatus("status").notNull().default("pending"),
    submittedAt: timestamp("submitted_at", { withTimezone: true }),
    checkedAt: timestamp("checked_at", { withTimezone: true }),
    teacherFeedback: text("teacher_feedback"),
  },
  (table) => [
    uniqueIndex("homework_submissions_homework_student_unique").on(
      table.homeworkId,
      table.studentId
    ),
  ]
);