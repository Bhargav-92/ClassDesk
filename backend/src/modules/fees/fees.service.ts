import { eq, getTableColumns, sql } from "drizzle-orm";
import { db } from "../../db/index.js";
import { feePayments, monthlyFees, students } from "../../db/schema.js";

export async function listFees(){
  const studentFees = await db.select({
    ...getTableColumns(feePayments),
    studentName: sql<string>`
    trim(concat_ws('',${students.fname}, ${students.lname}))`
  }).from(feePayments)
  .innerJoin(monthlyFees, eq(feePayments.monthlyFeeId , monthlyFees.id))
  .innerJoin(students,eq(monthlyFees.studentId, students.id))
  return studentFees
}
