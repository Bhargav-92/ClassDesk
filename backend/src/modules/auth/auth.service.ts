import { createHash, randomBytes, timingSafeEqual } from "node:crypto";
import { env } from "../../config/env.js";
import { AppError } from "../../utils/app-error.js";
import { HTTP_STATUS } from "../../utils/http-status.js";

const email = env.demoEmail.toLowerCase();
const password = env.demoPassword;
export const demoUser = { name: "Anjali", email };
const sessions = new Map<string, number>();
const sessionDurationMs = 12 * 60 * 60 * 1000;

function digest(value: string) {
  return createHash("sha256").update(value).digest();
}

export function login(emailInput: string, passwordInput: string) {
  const matches = emailInput.toLowerCase() === email &&
    timingSafeEqual(digest(passwordInput), digest(password));
  if (!matches) {
    throw new AppError(HTTP_STATUS.UNAUTHORIZED, "Email or password is incorrect");
  }

  const now = Date.now();
  for (const [token, expires] of sessions) {
    if (expires <= now) sessions.delete(token);
  }

  const token = randomBytes(32).toString("base64url");
  sessions.set(token, now + sessionDurationMs);
  return { token, user: demoUser };
}

export function verifySession(token: string): boolean {
  const expires = sessions.get(token);
  if (!expires || expires <= Date.now()) {
    sessions.delete(token);
    return false;
  }
  return true;
}

export function logout(token: string): void {
  sessions.delete(token);
}
