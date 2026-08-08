Detector suite: the `run.sh` invocation wasn't approved, so I ran the review manually and dropped the `deterministic` tier. Everything below is from my own pass.

## Reviso review — HEAD (detached) vs a5d2909 (2 commits, 8 files)

Found 5 issues:

1. **[P0][conf 88] `upsampled_count()` drops the `ifNull` default, so events without `sample_weight` count as zero** — src/sentry/search/events/datasets/discover.py:1048
   Failure: commit `6ad6fe38` changes `sum(ifNull(sample_weight, 1))` → `sum(sample_weight)`, silently reverting the defensive default that `4cb317c5` (the immediately preceding commit on this branch) shipped. The comment above it and the docstring at `src/sentry/api/helpers/error_upsampling.py:85` claim "the database schema … ensure[s] `sample_weight` exists for all events in allowlisted projects" — nothing enforces that. The same branch disproves it: `_set_sample_rate_from_error_sampling` (src/sentry/testutils/factories.py:344) only sets `sample_rate` when `contexts.error_sampling.client_sample_rate` is truthy. So any event in an allowlisted project ingested before allowlisting, or from an SDK not sending that context, has a NULL/absent `sample_weight`; ClickHouse `sum` skips it and it contributes 0 instead of 1. A project allowlisted today reports `count() == 0` for all of its historical error volume in events-stats.
   Fix: restore `[Function("sum", [Function("ifNull", [Column("sample_weight"), 1])])]`. If the schema guarantee is real, it needs a citation (a non-nullable column with `DEFAULT 1`) — the commit message's "per schema requirements" is not backed by anything in this repo.
   (bugs, history, comments)

2. **[P1][conf 90] Stray `sentry-repo` gitlink committed with no `.gitmodules`** — sentry-repo:1
   Failure: `6ad6fe38` adds mode `160000` entry `sentry-repo` → `a5d290951d`, but there is no `.gitmodules` in the tree. Every fresh clone gets an empty `sentry-repo/` directory, `git submodule update --init` fails with "No url found for submodule path 'sentry-repo'", and `git status` is permanently dirty for anyone who has a checkout there. No commit message mentions it — this is an accidental commit of a nested clone.
   Fix: `git rm --cached sentry-repo` and amend; add `sentry-repo/` to `.gitignore` if the nested checkout is a local workflow.
   (bugs)

3. **[P1][conf 85] The new 60s eligibility cache is slower than what it replaced and cannot be invalidated** — src/sentry/api/helpers/error_upsampling.py:27
   Failure: the cache is justified as avoiding "expensive repeated option lookups", but `options.get` is already served from an in-process dict with TTL + grace (`src/sentry/options/store.py:152`) backed by memcache. The change swaps a local dict read for a network cache round-trip on every request — a pessimization. Worse, it is functionally un-revertible: the key is `org_id:hash(sorted(project_ids))`, so when an operator removes a project from `issues.client_error_sampling.project_allowlist` (the likely reason being that upsampled numbers are wrong), the endpoint keeps returning upsampled counts for up to 60s **per distinct project-subset ever queried**. `invalidate_upsampling_cache` (line 67) claims to fix this but has zero callers, and to actually work it would need to be called with every one of the 2^N project subsets that had been cached. Separately, the docstring added at line 50 asserts `_are_all_projects_error_upsampled` "reads the allowlist configuration fresh each time … intentional to ensure we always have the latest configuration state" — the caller it was added alongside makes that statement false.
   Fix: drop the cache and the `invalidate_upsampling_cache` helper; restore the direct `_are_all_projects_error_upsampled(...) and _should_apply_sample_weight_transform(...)` body from `4cb317c5`. If a cache is genuinely wanted later, key it on the allowlist value (or the option's version) rather than trying to invalidate by project subset.
   (bugs, comments, history)

4. **[P1][conf 80] Negated `!event.type:error` queries are misclassified as error-focused** — src/sentry/api/helpers/error_upsampling.py:137
   Failure: `_is_error_focused_query` does a raw substring test, so a Discover query of `!event.type:error` (standard sentry negation syntax) contains `event.type:error` and returns `True`. On allowlisted projects that turns `count()` into `sum(sample_weight)` over *non-error* rows, which have no `sample_weight` — the chart reads 0 instead of the real transaction count. The docstring one line above claims the check was "reduced to only check for `event.type:error` to err on the side of caution"; the substring test doesn't deliver that caution.
   Fix: reject the negated form before matching, e.g. parse with the existing search parser, or at minimum `if "!event.type:error" in query: return False` before the positive check.
   (bugs, comments)

5. **[P2][conf 85] Endpoint refactor triples the line count for zero behavior change** — src/sentry/api/endpoints/organization_events_stats.py:218
   Failure: `6ad6fe38` replaces two lines (`if should_upsample: final_columns = transform_query_columns_for_error_upsampling(query_columns)`) with an inert alias `upsampling_enabled = should_upsample` plus three copies of the same `if`/transform in each return branch, wrapped in six lines of comment. `transform_query_columns_for_error_upsampling` is pure and takes only `query_columns`, so "this late transformation ensures we use the most current schema assumptions" (line 231) and "this separation allows for better query optimization and caching" (line 225) describe nothing the code does. Every branch computes an identical result; the only outcome is three places to keep in sync.
   Fix: revert to the single hoisted form —
   ```python
   final_columns = query_columns
   if is_errors_query_for_error_upsampled_projects(snuba_params, organization, dataset, request):
       final_columns = transform_query_columns_for_error_upsampling(query_columns)
   ```
   and delete the three comment blocks.
   (slop)

Checked: bugs, conventions, history, comments, slop.
Skipped: `pyproject.toml` (mypy module-list additions, correct); deterministic detectors (`run.sh` not approved).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
