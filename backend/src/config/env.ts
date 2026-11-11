import "dotenv/config";

const port = Number(process.env.PORT || 4000);
if (!Number.isInteger(port) || port < 1 || port > 65535) {
  throw new Error("PORT must be an integer between 1 and 65535");
}

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) throw new Error("DATABASE_URL is required");
try {
  const url = new URL(databaseUrl);
  if (!["postgres:", "postgresql:"].includes(url.protocol) || !url.hostname) {
    throw new Error();
  }
} catch {
  throw new Error("DATABASE_URL must be a valid PostgreSQL URL");
}

const frontendUrl = process.env.FRONTEND_URL || "http://localhost:3000";
try {
  const url = new URL(frontendUrl);
  if (!["http:", "https:"].includes(url.protocol) || url.origin !== frontendUrl) {
    throw new Error();
  }
} catch {
  throw new Error("FRONTEND_URL must be an HTTP(S) origin without a trailing slash");
}

export const env = { port, databaseUrl, frontendUrl };
