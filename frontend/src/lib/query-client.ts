import { QueryClient } from "@tanstack/react-query";

// Created inside the root's useState: one client per SSR tree, stable in the browser.
export function createQueryClient() {
	return new QueryClient({
		defaultOptions: { queries: { staleTime: 30_000, retry: 1 } },
	});
}
