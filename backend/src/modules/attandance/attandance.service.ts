import { eq, getTableColumns, sql } from "drizzle-orm";
import { db } from "../../db/index.js";
import { attendance, students } from "../../db/schema.js";

export async function attandanceList(){
  return db.select({
    ...getTableColumns(attendance),
    studentName: sql<string>`
    trim(concat_ws(' ',${students.fname}, ${students.lname}))`
  }).from(attendance)
  .innerJoin(students , eq(attendance.studentId ,students.id))
}
