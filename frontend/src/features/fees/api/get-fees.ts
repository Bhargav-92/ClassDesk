import { api } from "@/lib/api";
import type { FeesResponse } from "../types/fees";
export async function getFees(signal?: AbortSignal): Promise<FeesResponse> {
	const response = await api.get<FeesResponse>("/fees", { signal });
	const body = response.data;
	if (
		!body ||
		body.success !== true ||
		!Array.isArray(body.data) ||
		!body.data.every(
			(p) =>
				p &&
				typeof p.id === "string" &&
				typeof p.monthlyFeeId === "string" &&
				typeof p.studentName === "string" &&
				Number.isInteger(p.feesAmount) &&
				p.feesAmount > 0 &&
				typeof p.paidOn === "string" &&
				/^\d{4}-\d{2}-\d{2}$/.test(p.paidOn) &&
				!Number.isNaN(Date.parse(p.paidOn)) &&
				typeof p.recordedAt === "string" &&
				!Number.isNaN(Date.parse(p.recordedAt)),
		)
	)
		throw new Error("The payment response could not be read.");
	return body;
}
