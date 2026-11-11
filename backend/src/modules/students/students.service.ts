import { db } from "../../db/index.js";
import { students } from "../../db/schema.js";
import type { CreateStudentPayload, Student } from "./types/students.types.js";

export async function listStudents(): Promise<Student[]> {
 const studentList = await db.select().from(students)
 return studentList
}

export async function createStudent(payload: CreateStudentPayload): Promise<Student> {
  const dueDate = new Date(`${payload.joinedOn}T00:00:00Z`);
  const targetMonth = dueDate.getUTCMonth() + 1;
  dueDate.setUTCMonth(targetMonth);
  if (dueDate.getUTCMonth() !== targetMonth % 12) dueDate.setUTCDate(0);

  const [student] = await db
    .insert(students)
    .values({
      ...payload,
      feeDueDate: dueDate.toISOString().slice(0, 10),
      fname: payload.fname.trim(),
      lname: payload.lname.trim(),
      parentfName: payload.parentfName?.trim() || null,
      parentlName: payload.parentlName?.trim() || null,
      parentWhatsapp: payload.parentWhatsapp?.trim() || null,
    })
    .returning();

  return student;
}

