"""Refresh official skill snapshots; run from any directory with Python 3.

Only downloads static files from the official repositories below. Existing
files are never deleted. Review the resulting diff before committing a refresh.
"""
import hashlib
import json
from pathlib import Path
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent / "skills"
SOURCES = [
    ("shadcn-ui/ui", "shadcn", ["skills/shadcn/"], ""),
    ("TanStack/router", "tanstack-router", [
        "packages/router-core/skills/", "packages/react-router/skills/",
    ], "references/upstream/"),
    ("TanStack/table", "tanstack-table", [
        "packages/table-core/skills/", "packages/react-table/skills/",
    ], "references/upstream/"),
    ("TanStack/query", "tanstack-query", [], "references/upstream/"),
]
QUERY_DOCS = [
    "quick-start", "guides/important-defaults", "guides/query-keys",
    "guides/query-options", "guides/query-invalidation",
    "guides/optimistic-updates", "guides/ssr", "guides/query-cancellation",
    "guides/paginated-queries", "guides/infinite-queries",
]


def read(url):
    request = Request(url, headers={"User-Agent": "class-desk-skill-sync"})
    with urlopen(request, timeout=60) as response:
        return response.read()


def main():
    manifest = {"schemaVersion": 1, "sources": []}
    for repo, skill, prefixes, destination in SOURCES:
        tree = json.loads(read(f"https://api.github.com/repos/{repo}/git/trees/main?recursive=1"))
        if tree.get("truncated"):
            raise RuntimeError(f"Incomplete tree for {repo}")
        revision = tree["sha"]
        paths = [item["path"] for item in tree["tree"]
                 if item["type"] == "blob" and any(item["path"].startswith(p) for p in prefixes)]
        if repo == "TanStack/query":
            paths += [f"docs/framework/react/{doc}.md" for doc in QUERY_DOCS]
        licenses = [item["path"] for item in tree["tree"]
                    if item["type"] == "blob" and "/" not in item["path"]
                    and item["path"].lower().startswith("license")]
        if not licenses:
            raise RuntimeError(f"No upstream license found for {repo}")
        paths += licenses
        files = []
        for source_path in sorted(set(paths)):
            if source_path in licenses:
                relative = f"{skill}/LICENSE.upstream"
            elif repo == "shadcn-ui/ui":
                relative = f"{skill}/" + source_path.removeprefix("skills/shadcn/")
            else:
                relative = f"{skill}/{destination}{source_path}"
            content = read(f"https://raw.githubusercontent.com/{repo}/{revision}/{source_path}")
            target = ROOT / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(content)
            files.append({"path": relative, "upstreamPath": source_path,
                          "sha256": hashlib.sha256(content).hexdigest()})
        manifest["sources"].append({"repository": f"https://github.com/{repo}",
                                    "revision": revision, "skill": skill, "files": files})
        print(f"{skill}: {len(files)} official files at {revision}", flush=True)
    (ROOT / "sources.lock.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
