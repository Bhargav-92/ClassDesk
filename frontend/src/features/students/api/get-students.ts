import { api } from "@/lib/api";
import { parseStudentsResponse } from "../schemas/students-schema";
import type { StudentsResponse } from "../types/students";

export async function getStudents(
	signal?: AbortSignal,
): Promise<StudentsResponse> {
	const response = await api.get<StudentsResponse>("/students", { signal });
	return parseStudentsResponse(response.data);
}
