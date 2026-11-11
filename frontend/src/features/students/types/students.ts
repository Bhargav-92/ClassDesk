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
	feeDueDay: number;
}

export type StudentsResponse = ApiResponse<Student[]>;
