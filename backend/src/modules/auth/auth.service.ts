import { createHash, randomBytes, timingSafeEqual } from "node:crypto";
import { AppError } from "../../utils/app-error.js";

const email = (process.env.DEMO_EMAIL || "anjali@gmail.com").toLowerCase();
const password = process.env.DEMO_PASSWORD || "anjali@123";
export const demoUser = { name: "Anjali", email };
const sessions = new Map<string, number>();
const duration = 12 * 60 * 60 * 1000;
const digest = (value: string) => createHash("sha256").update(value).digest();

export function login(emailInput: string, passwordInput: string) {
 if (emailInput.toLowerCase() !== email || !timingSafeEqual(digest(passwordInput), digest(password))) throw new AppError(401, "Email or password is incorrect");
 for (const [token, expires] of sessions) if (expires <= Date.now()) sessions.delete(token);
 const token = randomBytes(32).toString("base64url");
 sessions.set(token, Date.now() + duration);
 return { token, user: demoUser };
}
export function verifySession(token: string): boolean {
 const expires = sessions.get(token);
 if (!expires || expires <= Date.now()) { sessions.delete(token); return false; }
 return true;
}
export function logout(token: string) { sessions.delete(token); }
