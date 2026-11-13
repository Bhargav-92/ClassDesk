import { z } from "zod";
import { AppError } from "../../utils/app-error.js";
import { HTTP_STATUS } from "../../utils/http-status.js";

const loginSchema = z.object({
  email: z.string().trim().email().max(254),
  password: z.string().min(1).max(128),
});

export function parseLogin(body: unknown) {
  const result = loginSchema.safeParse(body);
  if (!result.success) {
    throw new AppError(HTTP_STATUS.BAD_REQUEST, "Enter a valid email and password");
  }
  return result.data;
}
