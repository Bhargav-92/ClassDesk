# Attendance create endpoint

The Mark attendance sheet uses React Hook Form. Its request is prepared in `src/features/attendance/api/create-attendance.ts`.

Expected endpoint: `POST /api/attandance` (matching the current backend spelling).

```json
{
  "studentId": "existing-student-uuid",
  "classDate": "2026-11-11",
  "status": "present"
}
```

Supported statuses: `present`, `absent`, `late`.

Return HTTP 201 with `{ "success": true, "message": "Attendance saved", "data": { ...createdRecord } }`. The frontend then invalidates the attendance list and closes the sheet. Errors should return `{ "success": false, "message": "Readable explanation" }`; they stay visible in the form without clearing fields.

Validate UUID, student existence, real date, supported status, date on/after student joining and no future class date. Enforce the existing unique `(student_id, class_date)` constraint and return 409 for duplicates. No POST route has been added by this frontend change.
