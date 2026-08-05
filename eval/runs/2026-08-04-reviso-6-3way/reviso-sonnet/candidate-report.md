## Reviso review — HEAD vs cb3f63a4 (19 commits, 57 files)

Found 1 issue:

1. [P2][conf 85] Root CLAUDE.md's Scope section now contradicts the repo it describes — `CLAUDE.md:41-43`
   Failure: The Scope section reads "The plugin itself — `.claude-plugin/`, `commands/`, `skills/`, `agents/`, and the `eval/` corpus — is not here yet." This diff adds exactly that surface (`.claude-plugin/plugin.json`, `commands/review.md`, `commands/audit.md`, `agents/reviso-*.md`, `skills/reviso/`, `eval/corpus/`) across 19 commits, but never touches `CLAUDE.md` itself (confirmed empty `git diff cb3f63a4..HEAD -- CLAUDE.md`). A contributor or agent reading root CLAUDE.md next will be told to "grep for `TODO(plugin)`" to find what's missing, when the plugin has already landed — the doc-staleness scenario the finding schema calls out by name.
   Fix: Update or remove the Scope section (and its TODO(plugin) pointer) now that the plugin build has landed — e.g. replace it with a short "where things live" pointer to `CONTRIBUTING.md`'s map, which this same diff added.
   (conventions — doc staleness)

Checked: bugs, conventions, history, comments, slop, deterministic.
Skipped: eval/runs/**/* and eval/reference/* (archived/vendored machine output, kept verbatim per repo convention — not prose to review); openspec/**/*.md (planning docs, not shipped behavior); .lycheeignore/.markdownlint-cli2.jsonc config edits (mechanical, config-governed).
