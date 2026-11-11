import { api } from "@/lib/api";
import type { ApiResponse } from "@/types/api";
import type { AuthUser, LoginPayload } from "../types/auth";
export async function login(payload: LoginPayload) {
	const { data } = await api.post<
		ApiResponse<{ token: string; user: AuthUser }>
	>("/auth/login", payload);
	return data;
}
export async function getSession() {
	const { data } = await api.get<ApiResponse<AuthUser>>("/auth/me");
	return data;
}
export async function logout() {
	const { data } = await api.post<{ success: boolean; message: string }>(
		"/auth/logout",
	);
	return data;
}
