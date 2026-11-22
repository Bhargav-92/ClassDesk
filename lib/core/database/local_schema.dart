enum LocalTable {
  students('students', {
    'name': "TEXT NOT NULL CHECK (length(trim(name)) > 0)",
    'batch': "TEXT NOT NULL CHECK (length(trim(batch)) > 0)",
    'parent_name': "TEXT NOT NULL",
    'parent_whatsapp':
        "TEXT NOT NULL CHECK (length(parent_whatsapp) = 13 AND substr(parent_whatsapp, 1, 3) = '+91' AND substr(parent_whatsapp, 4) NOT GLOB '*[^0-9]*')",
    'monthly_fee_paise': "INTEGER NOT NULL CHECK (monthly_fee_paise >= 0)",
    'joining_date': "TEXT NOT NULL",
    'notes': "TEXT",
  }),
  feePlans('fee_plans', {
    'student_id': "TEXT NOT NULL REFERENCES students(id)",
    'amount_paise': "INTEGER NOT NULL CHECK (amount_paise >= 0)",
    'due_day': "INTEGER NOT NULL CHECK (due_day BETWEEN 1 AND 31)",
  }),
  feeRecords('fee_records', {
    'student_id': "TEXT NOT NULL REFERENCES students(id)",
    'month': "TEXT NOT NULL",
    'amount_due_paise': "INTEGER NOT NULL CHECK (amount_due_paise >= 0)",
    'due_date': "TEXT NOT NULL",
  }),
  payments('payments', {
    'fee_record_id': "TEXT NOT NULL REFERENCES fee_records(id)",
    'amount_paise': "INTEGER NOT NULL CHECK (amount_paise > 0)",
    'paid_on': "TEXT NOT NULL",
    'mode': "TEXT NOT NULL CHECK (mode IN ('cash', 'upi', 'razorpay'))",
    'razorpay_payment_id': "TEXT UNIQUE",
    'note': "TEXT",
  }),
  promises('promises', {
    'fee_record_id': "TEXT NOT NULL REFERENCES fee_records(id)",
    'remaining_amount_paise':
        "INTEGER NOT NULL CHECK (remaining_amount_paise > 0)",
    'promised_date': "TEXT NOT NULL",
    'reminder_sent':
        "INTEGER NOT NULL DEFAULT 0 CHECK (reminder_sent IN (0, 1))",
  }),
  homework('homework', {
    'student_id': 'TEXT REFERENCES students(id)',
    'batch': "TEXT NOT NULL",
    'subject': "TEXT NOT NULL",
    'title': "TEXT NOT NULL",
    'description': "TEXT NOT NULL",
    'due_date': "TEXT NOT NULL",
  }),
  messageLog('message_log', {
    'student_id': "TEXT NOT NULL REFERENCES students(id)",
    'homework_id': "TEXT REFERENCES homework(id)",
    'type': "TEXT NOT NULL CHECK (type IN ('fee_reminder', 'homework'))",
    'sent_at': "INTEGER NOT NULL",
  });

  const LocalTable(this.sqlName, this.columns);

  final String sqlName;
  final Map<String, String> columns;

  String get createSql =>
      '''
    CREATE TABLE $sqlName (
      id TEXT PRIMARY KEY NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL CHECK (updated_at >= created_at),
      is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1)),
      sync_status TEXT NOT NULL DEFAULT 'pending'
        CHECK (sync_status IN ('pending', 'synced', 'failed')),
      ${columns.entries.map((entry) => '${entry.key} ${entry.value}').join(', ')}
    )
  ''';

  /// Active rows are visible only while their owning records are active.
  String get visibleWhere => switch (this) {
    LocalTable.feePlans || LocalTable.feeRecords || LocalTable.messageLog =>
      'is_deleted = 0 AND student_id IN (SELECT id FROM students WHERE is_deleted = 0)',
    LocalTable.payments || LocalTable.promises =>
      'is_deleted = 0 AND fee_record_id IN '
          '(SELECT id FROM fee_records WHERE ${LocalTable.feeRecords.visibleWhere})',
    _ => 'is_deleted = 0',
  };
}

const localIndexes = [
  'CREATE INDEX students_batch ON students(batch, name)',
  'CREATE INDEX fee_plans_student ON fee_plans(student_id)',
  'CREATE UNIQUE INDEX fee_records_student_month '
      'ON fee_records(student_id, month) WHERE is_deleted = 0',
  'CREATE INDEX payments_fee ON payments(fee_record_id)',
  'CREATE INDEX promises_fee ON promises(fee_record_id)',
  'CREATE INDEX promises_due ON promises(promised_date, reminder_sent)',
  'CREATE INDEX homework_batch_due ON homework(batch, due_date)',
  'CREATE INDEX message_log_student ON message_log(student_id, sent_at)',
  'CREATE INDEX message_log_homework ON message_log(homework_id, student_id)',
];
