import { AppError } from "../../utils/app-error.js";
import { HTTP_STATUS } from "../../utils/http-status.js";
import { createAttendanceSchema } from "./schemas/create-attandance.schemas.js";

export function parseCreateAttendance(value: unknown) {
  const result = createAttendanceSchema.safeParse(value);
  if (!result.success) {
    throw new AppError(HTTP_STATUS.BAD_REQUEST, result.error.issues[0]?.message ?? "Invalid attendance details");
  }
  return result.data;
}
