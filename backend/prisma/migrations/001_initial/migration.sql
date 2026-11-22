CREATE TABLE IF NOT EXISTS students (
  id uuid PRIMARY KEY,
  created_at bigint NOT NULL,
  updated_at bigint NOT NULL CHECK (updated_at >= created_at),
  is_deleted boolean NOT NULL DEFAULT false,
  sync_status text NOT NULL DEFAULT 'synced' CHECK (sync_status IN ('pending','synced','failed')),
  name text NOT NULL,
  batch text NOT NULL,
  parent_name text NOT NULL,
  parent_whatsapp text NOT NULL,
  monthly_fee_paise bigint NOT NULL,
  joining_date text NOT NULL,
  notes text,
  CHECK (btrim(name) <> '' AND btrim(batch) <> '' AND parent_whatsapp ~ '^\+91[0-9]{10}$' AND monthly_fee_paise >= 0)
);

CREATE TABLE IF NOT EXISTS fee_plans (
  id uuid PRIMARY KEY,
  created_at bigint NOT NULL,
  updated_at bigint NOT NULL CHECK (updated_at >= created_at),
  is_deleted boolean NOT NULL DEFAULT false,
  sync_status text NOT NULL DEFAULT 'synced' CHECK (sync_status IN ('pending','synced','failed')),
  student_id uuid NOT NULL REFERENCES students(id),
  amount_paise bigint NOT NULL,
  due_day integer NOT NULL,
  CHECK (amount_paise >= 0 AND due_day BETWEEN 1 AND 31)
);

CREATE TABLE IF NOT EXISTS fee_records (
  id uuid PRIMARY KEY,
  created_at bigint NOT NULL,
  updated_at bigint NOT NULL CHECK (updated_at >= created_at),
  is_deleted boolean NOT NULL DEFAULT false,
  sync_status text NOT NULL DEFAULT 'synced' CHECK (sync_status IN ('pending','synced','failed')),
  student_id uuid NOT NULL REFERENCES students(id),
  month text NOT NULL,
  amount_due_paise bigint NOT NULL,
  due_date text NOT NULL,
  CHECK (amount_due_paise >= 0)
);

CREATE TABLE IF NOT EXISTS payments (
  id uuid PRIMARY KEY,
  created_at bigint NOT NULL,
  updated_at bigint NOT NULL CHECK (updated_at >= created_at),
  is_deleted boolean NOT NULL DEFAULT false,
  sync_status text NOT NULL DEFAULT 'synced' CHECK (sync_status IN ('pending','synced','failed')),
  fee_record_id uuid NOT NULL REFERENCES fee_records(id),
  amount_paise bigint NOT NULL,
  paid_on text NOT NULL,
  mode text NOT NULL,
  razorpay_payment_id text,
  note text,
  CHECK (amount_paise > 0 AND mode IN ('cash','upi','razorpay')), UNIQUE (razorpay_payment_id)
);

CREATE TABLE IF NOT EXISTS promises (
  id uuid PRIMARY KEY,
  created_at bigint NOT NULL,
  updated_at bigint NOT NULL CHECK (updated_at >= created_at),
  is_deleted boolean NOT NULL DEFAULT false,
  sync_status text NOT NULL DEFAULT 'synced' CHECK (sync_status IN ('pending','synced','failed')),
  fee_record_id uuid NOT NULL REFERENCES fee_records(id),
  remaining_amount_paise bigint NOT NULL,
  promised_date text NOT NULL,
  reminder_sent boolean NOT NULL,
  CHECK (remaining_amount_paise > 0)
);

CREATE TABLE IF NOT EXISTS homework (
  id uuid PRIMARY KEY,
  created_at bigint NOT NULL,
  updated_at bigint NOT NULL CHECK (updated_at >= created_at),
  is_deleted boolean NOT NULL DEFAULT false,
  sync_status text NOT NULL DEFAULT 'synced' CHECK (sync_status IN ('pending','synced','failed')),
  batch text NOT NULL,
  subject text NOT NULL,
  title text NOT NULL,
  description text NOT NULL,
  due_date text NOT NULL
);

CREATE TABLE IF NOT EXISTS message_log (
  id uuid PRIMARY KEY,
  created_at bigint NOT NULL,
  updated_at bigint NOT NULL CHECK (updated_at >= created_at),
  is_deleted boolean NOT NULL DEFAULT false,
  sync_status text NOT NULL DEFAULT 'synced' CHECK (sync_status IN ('pending','synced','failed')),
  student_id uuid NOT NULL REFERENCES students(id),
  homework_id uuid REFERENCES homework(id),
  type text NOT NULL,
  sent_at bigint NOT NULL,
  CHECK (type IN ('fee_reminder','homework') AND ((type = 'homework') = (homework_id IS NOT NULL)))
);

CREATE UNIQUE INDEX IF NOT EXISTS fee_records_active_month
  ON fee_records(student_id, month) WHERE NOT is_deleted;

CREATE TABLE IF NOT EXISTS sync_clock (
  id integer PRIMARY KEY CHECK (id = 1),
  revision bigint NOT NULL
);
INSERT INTO sync_clock (id, revision) VALUES (1, 0) ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS sync_changes (
  revision bigint PRIMARY KEY,
  table_name text NOT NULL,
  row_data jsonb NOT NULL
);