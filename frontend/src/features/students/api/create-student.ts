import { api, type ApiError } from "@/lib/api";
import type { ApiResponse } from "@/types/api";
import type { CreateStudentPayload, Student } from "../types/students";
export async function createStudent(
	payload: CreateStudentPayload,
): Promise<ApiResponse<Student>> {
	try {
		const response = await api.post<ApiResponse<Student>>("/students", payload);
		if (response.data?.success !== true)
			throw new Error(response.data?.message || "Student could not be added.");
		return response.data;
	} catch (error) {
		if ((error as ApiError).status === 404)
			throw new Error(
				"Adding students is not available yet. Your details are still here; please try again once the service is ready.",
			);
		throw error;
	}
}
