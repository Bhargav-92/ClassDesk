import type { ApiResponse } from "@/types/api";
export interface FeePayment {
	id: string;
	monthlyFeeId: string;
	studentName: string;
	feesAmount: number;
	paidOn: string;
	recordedAt: string;
}
export type FeesResponse = ApiResponse<FeePayment[]>;
