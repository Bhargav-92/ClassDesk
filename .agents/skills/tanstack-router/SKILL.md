---
name: tanstack-router
description: Build or debug TanStack React Router routes, typed navigation, search parameters, loaders, authentication guards, and Router plus Query integration. Applies to @tanstack/react-router, not react-router-dom.
---

# TanStack Router

This entry point organizes unmodified official TanStack skills under
`references/upstream`. Source revisions and hashes are in `../sources.lock.json`.

Check package.json and the lockfile before applying examples. Preserve the existing
TanStack Start router factory and per-request context. Do not replace a Start app
with the standalone React Router setup shown in upstream examples. Do not edit the
generated route tree by hand.

Read these in order for Router work:

1. [Core routing skill](references/upstream/packages/router-core/skills/router-core/SKILL.md).
2. [React adapter skill](references/upstream/packages/react-router/skills/react-router/SKILL.md).

For a narrower task, load the relevant nested core skill: `search-params`,
`path-params`, `navigation`, `data-loading`, `auth-and-guards`,
`not-found-and-errors`, `code-splitting`, `ssr`, or `type-safety`.

For Query-backed route data, read the official
[Router and Query composition](references/upstream/packages/react-router/skills/compositions/router-query/SKILL.md)
and `../tanstack-query/SKILL.md`.

Upstream package IDs such as `@tanstack/router-core#router-core` refer to the
matching local snapshot above; loading them does not require installing Intent.
Use only the applicable sections and references, rather than loading every skill.

If installed APIs differ from the snapshots, use installed types and the
[official Router documentation](https://tanstack.com/router/latest/docs/overview).
Run the project's build and check the changed routes, navigation, loading, and
error behavior relevant to the task.
