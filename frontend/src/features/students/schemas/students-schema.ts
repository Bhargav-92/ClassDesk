import type { Student, StudentsResponse } from "../types/students";

function isStudent(value: unknown): value is Student {
	if (!value || typeof value !== "object") return false;
	const s = value as Record<string, unknown>;
	return (
		typeof s.id === "string" &&
		typeof s.fname === "string" &&
		typeof s.lname === "string" &&
		(s.parentfName === null || typeof s.parentfName === "string") &&
		(s.parentlName === null || typeof s.parentlName === "string") &&
		(s.parentWhatsapp === null || typeof s.parentWhatsapp === "string") &&
		typeof s.joinedOn === "string" &&
		/^\d{4}-\d{2}-\d{2}$/.test(s.joinedOn) &&
		!Number.isNaN(Date.parse(s.joinedOn)) &&
		new Date(s.joinedOn).toISOString().slice(0, 10) === s.joinedOn &&
		Number.isInteger(s.monthlyFee) &&
		(s.monthlyFee as number) >= 0 &&
		typeof s.feeDueDate === "string" &&
		/^\d{4}-\d{2}-\d{2}$/.test(s.feeDueDate) &&
		!Number.isNaN(Date.parse(s.feeDueDate))
	);
}

export function parseStudentsResponse(value: unknown): StudentsResponse {
	if (!value || typeof value !== "object")
		throw new Error("The student response could not be read.");
	const response = value as Record<string, unknown>;
	if (
		response.success !== true ||
		typeof response.message !== "string" ||
		!Array.isArray(response.data) ||
		!response.data.every(isStudent)
	) {
		throw new Error("The student response could not be read.");
	}
	return { success: true, message: response.message, data: response.data };
}
