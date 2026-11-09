---
name: tanstack-table
description: Build or debug TanStack React Table columns, row models, sorting, filtering, pagination, selection, controlled state, and Query-backed tables with custom or shadcn UI.
---

# TanStack Table

This entry point organizes unmodified official React and core Table skills.
Source revisions and hashes are in `../sources.lock.json`.

Inspect package.json, the lockfile, and installed declarations first. These
upstream snapshots target **v9**. Do not apply v9 examples to v8 code or upgrade
the library merely to match a skill. If Table is absent, choose a version in the
context of the requested implementation before installing it.

For v9, read the [core skill](references/upstream/packages/table-core/skills/core/SKILL.md)
before the [React getting-started skill](references/upstream/packages/react-table/skills/getting-started/SKILL.md).

Load further guidance only for the task:

- [Feature registration and individual feature references](references/upstream/packages/table-core/skills/table-features/SKILL.md).
- [Core state ownership](references/upstream/packages/table-core/skills/table-state/SKILL.md)
  and [React state](references/upstream/packages/react-table/skills/table-state/SKILL.md).
- [Custom features](references/upstream/packages/table-core/skills/custom-features/SKILL.md).
- [React migration checklist](references/upstream/packages/react-table/skills/migrate-v8-to-v9/SKILL.md), only for an actual migration task.
- Query and virtualization integration references linked from React getting-started.

Upstream package IDs such as `@tanstack/table-core#core` map to these local
snapshots. Intent is optional; read the corresponding file directly when it is
not installed.

For v8, use the [official v8 docs](https://tanstack.com/table/v8/docs/introduction)
and installed types instead of the v9 snapshots. The
[current docs](https://tanstack.com/table/latest/docs/overview) may describe a newer major.

Table provides the headless model; use the project's UI conventions for semantic
markup, keyboard interaction, labels, loading, empty, and error states. With
shadcn, also read `../shadcn/SKILL.md`. Verify sorting, filtering, pagination, and
selection against real data as applicable, including server-driven behavior.
