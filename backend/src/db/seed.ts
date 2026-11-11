import { db, pool } from "./index.js";
import { feePayments, monthlyFees, students } from "./schema.js";

async function main() {
  // ── 1. Insert students and get back their real UUIDs ──────────────────
  const insertedStudents = await db
    .insert(students)
    .values([
      {
        fname: "Aarav",
        lname: "Sharma",
        parentfName: "Neha",
        parentlName: "Sharma",
        parentWhatsapp: "9876543210",
        joinedOn: "2026-11-01",
        monthlyFee: 250000,
        feeDueDay: 5,
      },
      {
        fname: "Diya",
        lname: "Patel",
        parentfName: "Ravi",
        parentlName: "Patel",
        joinedOn: "2026-11-03",
        monthlyFee: 200000,
        feeDueDay: 10,
      },
    ])
    .returning({ id: students.id });

  console.log(`Inserted ${insertedStudents.length} students`);

  // ── 2. Use a real student UUID from the DB result ─────────────────────
  const studentId = insertedStudents[0].id; // actual UUID string from the DB

  await db.transaction(async (tx) => {
    // ── 3. Create a monthly fee record for that student ─────────────────
    const [monthlyFee] = await tx
      .insert(monthlyFees)
      .values({
        studentId,
        billingMonth: "2026-11-01",
        feeAmount: 250000, // ₹2,500 in paise
        dueOn: "2026-11-05",
      })
      .returning({ id: monthlyFees.id });

    // ── 4. Record a partial payment against that monthly fee ────────────
    await tx.insert(feePayments).values({
      monthlyFeeId: monthlyFee.id,
      feesAmount: 100000, // ₹1,000 partial payment in paise
      paidOn: "2026-11-04",
    });

    console.log("Inserted monthly fee and payment for student", studentId);
  });
}

try {
  await main();
} catch (error) {
  console.error("Seed failed:", error);
  process.exitCode = 1;
} finally {
  await pool.end();
}