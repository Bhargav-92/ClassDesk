import { api, type ApiError } from "@/lib/api";
import type { ApiResponse } from "@/types/api";
import type {
	AttendanceRecord,
	CreateAttendancePayload,
} from "../types/attendance";

export async function createAttendance(
	payload: CreateAttendancePayload,
): Promise<ApiResponse<AttendanceRecord>> {
	try {
		const response = await api.post<ApiResponse<AttendanceRecord>>(
			"/attandance",
			payload,
		);
		if (response.data?.success !== true)
			throw new Error(
				response.data?.message || "Attendance could not be saved.",
			);
		return response.data;
	} catch (error) {
		if ((error as ApiError).status === 404)
			throw new Error(
				"Saving attendance is not available yet. Please try again once the service is ready.",
			);
		throw error;
	}
}
