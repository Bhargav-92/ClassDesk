import { env } from "../config/env.js";
import { drizzle } from "drizzle-orm/node-postgres";
import { Pool } from "pg";

export const pool = new Pool({
  connectionString: env.databaseUrl,
  connectionTimeoutMillis: 5000,
});

export const db = drizzle(pool);
