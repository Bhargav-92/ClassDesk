import { randomBytes } from "node:crypto";
import { compare, hash } from "bcryptjs";
import { AppError } from "../../utils/app-error.js";
import { HTTP_STATUS } from "../../utils/http-status.js";
import { findUserByEmail } from "./auth.repository.js";

type AuthUser = { id: string; name: string; email: string };
const sessions = new Map<string, { user: AuthUser; expires: number }>();
const sessionDurationMs = 12 * 60 * 60 * 1000;
// Perform password work even when the email is unknown.
const dummyHash = hash(randomBytes(32).toString("hex"), 12);

export async function login(email: string, password: string) {
  const record = await findUserByEmail(email.trim());
  const matches = await compare(password, record?.passwordHash ?? await dummyHash);
  if (!record || !matches) {
    throw new AppError(HTTP_STATUS.UNAUTHORIZED, "Email or password is incorrect");
  }
  const now = Date.now();
  for (const [token, session] of sessions) {
    if (session.expires <= now) sessions.delete(token);
  }
  const user = { id: record.id, name: record.name, email: record.email };
  const token = randomBytes(32).toString("base64url");
  sessions.set(token, { user, expires: now + sessionDurationMs });
  return { token, user };
}

export function getSessionUser(token: string): AuthUser | undefined {
  const session = sessions.get(token);
  if (!session || session.expires <= Date.now()) {
    sessions.delete(token);
    return undefined;
  }
  return session.user;
}

export function verifySession(token: string): boolean {
  return Boolean(getSessionUser(token));
}

export function logout(token: string): void {
  sessions.delete(token);
}
