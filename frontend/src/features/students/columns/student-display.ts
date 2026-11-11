import type { Student } from "../types/students";

export const studentName = (student: Student) =>
	[student.fname, student.lname].filter(Boolean).join(" ").trim();

export const parentName = (student: Student) =>
	[student.parentfName, student.parentlName].filter(Boolean).join(" ").trim();
