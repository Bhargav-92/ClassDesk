export function createQueryKeys<
	TScope extends string,
	TFilter extends object = Record<string, unknown>,
	TId extends string | number = string,
>(scope: TScope) {
	return {
		all: [scope] as const,
		lists: () => [scope, "list"] as const,
		list: (filters?: TFilter) => [scope, "list", filters ?? {}] as const,
		details: () => [scope, "detail"] as const,
		detail: (id: TId) => [scope, "detail", id] as const,
	};
}
