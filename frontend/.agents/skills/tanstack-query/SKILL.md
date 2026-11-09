---
name: tanstack-query
description: Implement or debug TanStack React Query server-state fetching, cache keys, mutations, invalidation, optimistic updates, pagination, cancellation, and SSR hydration.
---

# TanStack Query

This is a locally authored skill backed by official TanStack Query documentation,
not an upstream-authored SKILL.md. The official repository had no SKILL.md at the
recorded revision. Unmodified documentation snapshots and their hashes are
recorded in `../sources.lock.json`.

The snapshots contain selected pages, not the entire documentation site. Resolve
links to pages outside this snapshot against the official documentation website
(for example, a guide's `./filters.md` link maps to
`https://tanstack.com/query/latest/docs/framework/react/guides/filters`).

Inspect the installed Query major and existing provider, query-key conventions,
and SSR integration before changing code. These references describe React Query
v5; confirm APIs against installed types. Do not add Query just because a task
uses async data if the requested behavior already fits the project's loader.

Read [quick start](references/upstream/docs/framework/react/quick-start.md) for
setup and [important defaults](references/upstream/docs/framework/react/guides/important-defaults.md)
before choosing cache lifetimes or refetch behavior.

Use a stable QueryClient for the browser application. For server rendering,
follow the [SSR guide](references/upstream/docs/framework/react/guides/ssr.md)
and the existing framework integration so caches do not leak between requests.

Load the reference matching the task:

- [Query keys](references/upstream/docs/framework/react/guides/query-keys.md): include variables that affect the fetched data; keep keys serializable.
- [Query options](references/upstream/docs/framework/react/guides/query-options.md): share typed options between components and route prefetching.
- [Invalidation](references/upstream/docs/framework/react/guides/query-invalidation.md): invalidate affected keys after successful mutations.
- [Optimistic updates](references/upstream/docs/framework/react/guides/optimistic-updates.md): choose UI or cache updates and handle rollback and reconciliation.
- [Cancellation](references/upstream/docs/framework/react/guides/query-cancellation.md): pass the supplied AbortSignal through to the transport when cancellation is needed.
- [Pagination](references/upstream/docs/framework/react/guides/paginated-queries.md) and [infinite queries](references/upstream/docs/framework/react/guides/infinite-queries.md): use distinct keys and the installed version's page options.

For Router integration, read `../tanstack-router/SKILL.md` and its Query
composition reference. Reuse the same client and options for prefetch and render.
For server-driven tables, put pagination, filtering, and sorting inputs in the
query key and read `../tanstack-table/SKILL.md`.

Handle initial loading, background fetching, errors, and empty results according
to the intended UI. Check the build and verify relevant fetch, mutation, and
cache behavior. Consult [official docs](https://tanstack.com/query/latest/docs/framework/react/overview)
when the installed version differs or a required topic is not in the snapshots.
