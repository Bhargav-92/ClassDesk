import { MutationCache, QueryCache, QueryClient } from "@tanstack/react-query";
import { toast } from "sonner";

interface MutationMeta extends Record<string, unknown> {
	successMessage?: string;
}
declare module "@tanstack/react-query" {
	interface Register {
		mutationMeta: MutationMeta;
	}
}
function backendMessage(data: unknown): string | undefined {
	if (
		data &&
		typeof data === "object" &&
		"message" in data &&
		typeof data.message === "string"
	)
		return data.message.trim() || undefined;
}

// Each SSR tree owns its client; toast callbacks execute on browser requests.
export function createQueryClient() {
	return new QueryClient({
		mutationCache: new MutationCache({
			onSuccess: (data, _variables, _context, mutation) => {
				const message = backendMessage(data) || mutation.meta?.successMessage;
				if (message && typeof window !== "undefined") toast.success(message);
			},
			onError: (error) => {
				if (typeof window !== "undefined") toast.error(error.message);
			},
		}),
		queryCache: new QueryCache({
			onError: (error) => {
				if (typeof window !== "undefined") toast.error(error.message);
			},
		}),
		defaultOptions: { queries: { staleTime: 30_000, retry: 1 } },
	});
}
