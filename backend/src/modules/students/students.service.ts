import { db } from "../../db/index.js";
import { students } from "../../db/schema.js";


export async function listStudents(){
 const studentList = await db.select().from(students)
 return studentList
}