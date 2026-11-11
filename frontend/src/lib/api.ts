import axios, { type AxiosError } from "axios";

export interface ApiError extends Error {
	status: number;
}

export const api = axios.create({
	baseURL: `${(import.meta.env.VITE_API_URL || "http://localhost:4000").replace(/\/$/, "")}/api`,
	withCredentials: true,
	timeout: 30_000,
	headers: { "Content-Type": "application/json" },
});

api.interceptors.response.use(
	(response) => response,
	(error: AxiosError<{ message?: string }>) => {
		const normalized: ApiError = Object.assign(
			new Error(
				error.response?.data?.message ||
					(error.response
						? `Request failed (${error.response.status}). Please try again.`
						: "Unable to reach your classroom. Please check your connection and try again."),
			),
			{ name: "ApiError", status: error.response?.status ?? 0 },
		);
		return Promise.reject(normalized);
	},
);
