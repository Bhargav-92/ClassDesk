import { api } from "@/lib/api";
import type { ApiResponse } from "@/types/api";
import type {
	CreatedAttendance,
	CreateAttendancePayload,
} from "../types/attendance";

export async function createAttendance(
	payload: CreateAttendancePayload,
): Promise<ApiResponse<CreatedAttendance>> {
	const response = await api.post<ApiResponse<CreatedAttendance>>(
		"/attandance",
		payload,
	);
	if (response.data?.success !== true)
		throw new Error(response.data?.message || "Attendance could not be saved.");
	return response.data;
}
