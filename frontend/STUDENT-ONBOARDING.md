# Student onboarding API

The Add student sheet sends `POST /api/students` through `api/create-student.ts` and `hooks/useCreateStudent.ts`.

```json
{
  "fname": "Aarav",
  "lname": "Sharma",
  "parentfName": "Neha",
  "parentlName": "Sharma",
  "parentWhatsapp": "+919876543210",
  "joinedOn": "2026-11-12",
  "monthlyFee": 250000
}
```

Monthly fee is in paise; the form accepts rupees. Blank optional parent fields are sent as null. Return HTTP 201 and `{ "success": true, "message": "Student added", "data": Student }`. The frontend invalidates the student list, closes the sheet and clears list filters on success. On failure it preserves the form and displays the API message. Backend validation should enforce the required names, valid joining date, integer non-negative fee within PostgreSQL integer range, and fee due date as YYYY-MM-DD. This change does not implement the POST route.

The backend owns fee due date calculation. The frontend does not collect or send feeDueDate during onboarding; it only displays the date returned by the backend.
