import { AppError } from "../../utils/app-error.js";
import { createStudentSchema } from "./schemas/create-student.schema.js";
import type { CreateStudentPayload } from "./types/students.types.js";

export function parseCreateStudent(value: unknown): CreateStudentPayload {
  const result = createStudentSchema.safeParse(value);
  if (!result.success) {
    const issue = result.error.issues[0];
    const field = issue.path.join(".");
    throw new AppError(400, field ? `${field}: ${issue.message}` : issue.message);
  }
  return result.data;
}

