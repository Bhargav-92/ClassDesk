import { sql } from "drizzle-orm";
import { db } from "../../db/index.js";
import { users } from "../../db/auth.schema.js";

export async function findUserByEmail(email: string) {
  const [user] = await db.select().from(users)
    .where(sql`lower(${users.email}) = ${email.toLowerCase()}`).limit(1);
  return user;
}
