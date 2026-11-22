export const tables = {
  "students": {
    "name": "s",
    "batch": "s",
    "parent_name": "s",
    "parent_whatsapp": "s",
    "monthly_fee_paise": "n",
    "joining_date": "s",
    "notes": "s?"
  },
  "fee_plans": {
    "student_id": "u@students",
    "amount_paise": "n",
    "due_day": "i"
  },
  "fee_records": {
    "student_id": "u@students",
    "month": "s",
    "amount_due_paise": "n",
    "due_date": "s"
  },
  "payments": {
    "fee_record_id": "u@fee_records",
    "amount_paise": "n",
    "paid_on": "s",
    "mode": "s",
    "razorpay_payment_id": "s?",
    "note": "s?"
  },
  "promises": {
    "fee_record_id": "u@fee_records",
    "remaining_amount_paise": "n",
    "promised_date": "s",
    "reminder_sent": "b"
  },
  "homework": {
    "student_id": "u?@students",
    "batch": "s",
    "subject": "s",
    "title": "s",
    "description": "s",
    "due_date": "s"
  },
  "message_log": {
    "student_id": "u@students",
    "homework_id": "u?@homework",
    "type": "s",
    "sent_at": "n"
  }
};