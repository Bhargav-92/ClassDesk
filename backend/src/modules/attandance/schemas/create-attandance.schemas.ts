import { z } from "zod";

export const createAttendanceSchema = z.strictObject({
  studentId: z.uuid({
    error: "A valid student ID is required",
  }),

  classDate: z.iso.date({
    error: "Class date must be a valid YYYY-MM-DD date",
  }),

  status: z.enum(["present", "absent", "late"], {
    error: "Status must be present, absent, or late",
  }),
});

export type CreateAttendancePayload = z.infer<
  typeof createAttendanceSchema
>;