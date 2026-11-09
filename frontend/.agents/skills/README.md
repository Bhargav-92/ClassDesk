# Project skills

Keep project skills here, one named folder per library:

| Skill | Source and scope |
| --- | --- |
| `shadcn` | Official `shadcn-ui/ui` skill and supporting files, unchanged. |
| `tanstack-query` | Local entry point backed by official TanStack Query React v5 documentation. |
| `tanstack-router` | Local entry point plus official Router core and React skill trees. |
| `tanstack-table` | Local entry point plus official Table v9 core and React skill trees. |

Read the relevant `SKILL.md` first; it routes to supporting material. The React
and framework-independent skills cover this React project. Other framework
adapters and unrelated libraries are intentionally outside this collection.

`sources.lock.json` records exact upstream commit IDs, paths, and SHA-256 hashes.
Each folder retains its upstream license. Files under `references/upstream` and
the shadcn snapshot are upstream content; make project-specific edits to the
local TanStack entry points instead.

To refresh from official repositories, run `python .agents/sync-skills.py` from
the project root with network access. Review the diff and version compatibility
before committing. The script does not install dependencies or run downloaded
code. It never deletes files; review upstream removals or renames during updates.

The requested reference repository,
https://github.com/auranics/keycubby-webapp/tree/main/.agents/skills,
returned HTTP 404 during setup. No content was copied from it.
