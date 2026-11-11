import type { z } from "zod";
import type { students } from "../../../db/schema.js";
import type { createStudentSchema } from "../schemas/create-student.schema.js";

export type Student = typeof students.$inferSelect;
export type CreateStudentInput = z.input<typeof createStudentSchema>;
export type CreateStudentPayload = z.output<typeof createStudentSchema>;
