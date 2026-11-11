import type { ApiResponse } from "@/types/api";
export type AttendanceStatus = "present" | "absent" | "late";
export interface AttendanceRecord {
	id: string;
	studentId: string;
	studentName: string;
	classDate: string;
	status: AttendanceStatus;
}
export type AttendanceResponse = ApiResponse<AttendanceRecord[]>;
