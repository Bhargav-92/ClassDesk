import type { ApiResponse } from "@/types/api";

export interface Student {
	id: string;
	fname: string;
	lname: string;
	parentfName: string | null;
	parentlName: string | null;
	parentWhatsapp: string | null;
	joinedOn: string;
	monthlyFee: number;
	feeDueDate: string;
}

export type StudentsResponse = ApiResponse<Student[]>;
export type CreateStudentPayload = Omit<Student, "id" | "feeDueDate">;
import type { z } from "zod";
import type { createStudentSchema } from "../schemas/create-student-schema";
export type StudentFormValues = z.infer<typeof createStudentSchema>;
