import { api } from "@/lib/api";
import type { AttendanceResponse } from "../types/attendance";
export async function getAttendance(
	signal?: AbortSignal,
): Promise<AttendanceResponse> {
	// Retain the backend's current endpoint spelling.
	const response = await api.get<AttendanceResponse>("/attandance", { signal });
	const body = response.data;
	if (
		!body ||
		body.success !== true ||
		!Array.isArray(body.data) ||
		!body.data.every(
			(r) =>
				r &&
				typeof r.id === "string" &&
				typeof r.studentId === "string" &&
				typeof r.studentName === "string" &&
				typeof r.classDate === "string" &&
				/^\d{4}-\d{2}-\d{2}$/.test(r.classDate) &&
				!Number.isNaN(Date.parse(r.classDate)) &&
				new Date(r.classDate).toISOString().slice(0, 10) === r.classDate &&
				["present", "absent", "late"].includes(r.status),
		)
	)
		throw new Error("The attendance response could not be read.");
	return body;
}
