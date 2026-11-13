import bcrypt from "bcryptjs";
import { db, pool } from "./index.js";
import { users } from "./auth.schema.js";

async function seed() {
  const passwordHash = await bcrypt.hash(
    "anjali@123",
    12,
  );

  const inserted = await db
    .insert(users)
    .values({
      name: "Anjali Thakar",
      email: "anjali@gmail.com",
      passwordHash,
    })
    .onConflictDoNothing()
    .returning({ id: users.id });

  console.log(
    inserted.length
      ? "User created successfully."
      : "Email already exists. Password was not changed.",
  );
}

seed()
  .catch(() => {
    console.error("Seeding failed. Check your database connection and table.");
    process.exitCode = 1;
  })
  .finally(() => pool.end());