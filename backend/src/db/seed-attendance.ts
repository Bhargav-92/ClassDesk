import { lte } from "drizzle-orm";
import { db, pool } from "./index.js";
import { attendance, students } from "./schema.js";

const classDate = "2026-11-11";

try {
  await db.transaction(async (tx) => {
    const studentList = await tx
      .select({ id: students.id })
      .from(students)
      .where(lte(students.joinedOn, classDate));

    if (studentList.length === 0) {
      console.log(`No students joined on or before ${classDate}; nothing to seed.`);
      return;
    }

    const inserted = await tx
      .insert(attendance)
      .values(studentList.map((student) => ({
        studentId: student.id,
        classDate,
        status: "present" as const,
      })))
      .onConflictDoNothing({ target: [attendance.studentId, attendance.classDate] })
      .returning({ id: attendance.id });

    console.log(`Seeded ${inserted.length} attendance records for ${classDate}; existing records were preserved.`);
  });
} catch (error) {
  console.error("Attendance seed failed:", error);
  process.exitCode = 1;
} finally {
  await pool.end();
}
