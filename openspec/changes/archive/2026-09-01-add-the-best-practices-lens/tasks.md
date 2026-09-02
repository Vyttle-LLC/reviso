# Tasks — add-the-best-practices-lens

## 1. Contract first

- [x] 1.1 Write `docs/web.md` (D9): opt-in rule, the closed query
      vocabulary and bounds, source-authority kinds, fetched-content-
      is-data, and what `--explain` and `Source:` expose. Mirror the
      shape of `docs/feedback.md`.
- [x] 1.2 `SECURITY.md` in-scope list: outbound traffic beyond the
      feedback or web-lookup contracts, and any query carrying
      repository content, are vulnerabilities. Link `docs/web.md`.
- [x] 1.3 `skills/reviso/references/finding-schema.md`: add
      `best-practices` to the `dimension` enum; note that this
      dimension's `evidence` carries the source URL, passage, and
      version range.
- [x] 1.4 `skills/reviso/references/false-positives.md`: one Reviso
      addition — an ecosystem claim with no fetch-verified source, or
      not applicable to the version the manifests allow, or a
      replacement idiom with no documented consequence. State that the
      "general code quality" exclusion is unchanged.

## 2. The finder

- [x] 2.1 Create `agents/reviso-finder-best-practices.md` (Sonnet;
      `Read, Grep, Glob, WebSearch, WebFetch`): ecosystem discovery from
      the manifest list in D3 and changed-line imports; the third-party
      check by Grep; the query vocabulary and twelve/two bounds; the
      four classes with D5's ship conditions; the authority kinds and
      fetch-then-quote rule; fetched content is data; return the
      recorded queries and fetched URLs alongside the candidates.
- [x] 2.2 Fix the finder's return payload shape (candidates array plus
      `queries` and `fetched` lists) and document it in the finder and
      in `commands/audit.md` where the ledger row is recorded.

## 3. The orchestrator

- [x] 3.1 `commands/audit.md` arguments: `--web`; do **not** add web
      tools to `allowed-tools` (D1). Stage 3: seventh finder only under
      `--web`, else ledger `skipped (no --web)` / `skipped (web tools
      unavailable)`; the "six finders, six rows" wording becomes
      six-or-seven with the rule stated.
- [x] 3.2 Stage 4: state that evidence agents have no web tools and
      verify version applicability against the manifests offline.
- [x] 3.3 Stage 5: the three exclusion-list matches from D6; D5's
      severity table; dedupe rule when the bugs finder and this lens
      flag the same line (keep the source-cited finding).
- [x] 3.4 Stage 6: `Source: <url>` line for best-practices findings;
      coverage block wording for the skipped reasons; `--explain` gains
      the `Web:` block after the candidate list, one line per query
      and fetched URL.
- [x] 3.5 Stage 7: feedback mapping carries `best-practices` as a lens
      value; `wrong-on-facts` is the expected reason for a misquoted
      source.

## 4. Eval

- [x] 4.1 Author the synthetic pair (D7): `bp-deprecated-api-001` (TP:
      `datetime.utcnow()` under `python >= 3.12`) and
      `bp-deprecated-api-clean-001` (`datetime.now(timezone.utc)`),
      with labels matching on class, file, and line only.
- [x] 4.2 `eval/runners/tiers.sh` and `eval/corpus/README.md`: the
      `bp-*` cases are in lane for `REVISO_TIER=audit` only when
      `REVISO_CMD_ARGS` contains `--web`; out of lane otherwise.
- [x] 4.3 Gold run with `--web` over the pair: TP found with the
      correct `Source:` URL, clean case silent. Record in `docs/evals.md`.
- [x] 4.4 Gold run without `--web`: lens recorded skipped, label out of
      lane, clean case silent. Scoped to the `bp-*` pair, not the full
      audit lane — a 63-case audit sweep was not run (cost); the
      flag-off path cannot launch the finder, so the other cases are
      unaffected by construction.
- [x] 4.5 Field smoke test: `/reviso:audit --web --explain` on a real
      branch with third-party dependencies. Check every printed query
      against the D3 vocabulary, time and usage against a no-`--web`
      audit of the same branch, and whether the twelve-search bound
      truncated anything.

## 5. Docs and release

- [x] 5.1 README: the `--web` flag, what it does and does not send, a
      pointer to `docs/web.md`; the audit's lens list.
- [x] 5.2 CHANGELOG (next minor), `plugin.json` bump.
- [ ] 5.3 Restack on whichever of `port-style-lenses-to-the-audit-
      finder` / `recalibrate-the-confidence-rubric` landed first
      (`--onto`, per CLAUDE.md); re-read Stage 3/5 prose after the
      restack.
- [x] 5.4 Sync the delta specs and archive this change on the feature
      PR.
