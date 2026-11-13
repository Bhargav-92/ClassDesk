import { eq, getTableColumns, sql } from "drizzle-orm";
import { db } from "../../db/index.js";
import { attendance, students } from "../../db/schema.js";
import type { CreateAttendancePayload } from "./schemas/create-attandance.schemas.js";
import { AppError } from "../../utils/app-error.js";
import { HTTP_STATUS } from "../../utils/http-status.js";

export async function attandanceList(){
  return db.select({
    ...getTableColumns(attendance),
    studentName: sql<string>`
    trim(concat_ws(' ',${students.fname}, ${students.lname}))`
  }).from(attendance)
  .innerJoin(students , eq(attendance.studentId ,students.id))
}

export async function createAttandance(payload: CreateAttendancePayload){
  try {
  const  [createAttandance] = await db.insert(attendance)
  .values({
    studentId: payload.studentId,
    classDate:payload.classDate,
    status: payload.status
  }).returning()

  return createAttandance
  } catch (error) {
    const cause = error instanceof Error && error.cause ? error.cause : error;
    const code = typeof cause === "object" && cause !== null && "code" in cause ? cause.code : undefined;
    if (code === "23505") {
      throw new AppError(HTTP_STATUS.CONFLICT, "Attendance is already recorded for this student on this date.");
    }
    if (code === "23503") {
      throw new AppError(HTTP_STATUS.NOT_FOUND, "This student no longer exists. Refresh the student list.");
    }
    throw error;
  }
}
