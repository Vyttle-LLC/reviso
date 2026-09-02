# Tasks — move-best-practices-to-style

## 1. Style gains the lens

- [x] 1.1 `commands/style.md`: frontmatter (description, argument-hint
      `--web`); `--web` in Arguments; cardinal rule gains the third
      named exception; the lens entry in Step 3 (ecosystem discovery,
      query vocabulary and 12/2 bounds, four classes, fetch-then-quote,
      fetched content is data, record queries/fetched URLs); dimension
      `best-practices`; seventeenth ledger row.
- [x] 1.2 Step 4: `no-source` drop reason; version/consequence as
      exclusion-list matches; style-rubric scoring framed as evidence
      quality (D4).
- [x] 1.3 Step 5: `ecosystem` family (own row, D5); `Source:` line;
      severity exception (D3); `Web:` block in `--explain`;
      skipped-reason wording. Step 6: lens → `best-practices` mapping.

## 2. Audit gives it up

- [x] 2.1 `commands/audit.md`: revert every 0.11.0 `--web` hunk — flag,
      report-only paragraph, seventh finder, ledger wording, Stage 4/5
      additions, Source line, Web block, Stage 7 sentence.
- [x] 2.2 Delete `agents/reviso-finder-best-practices.md`.

## 3. Contract and docs

- [x] 3.1 `docs/web.md`: audit → style throughout; finder → inline
      lens; truncation order per the modified contract scenario.
- [x] 3.2 `skills/reviso/references/finding-schema.md` note and
      `SECURITY.md` bullet: confirm command-agnostic wording, adjust if
      either names the audit.
- [x] 3.3 `README.md`: `--web` sentence moves from the audit bullet to
      the style bullet; style's "two deliberate exceptions" becomes
      three; status paragraph.

## 4. Eval

- [x] 4.1 `eval/corpus/public.jsonl` bp-* notes and
      `eval/corpus/README.md`: style tier; `eval/runners/candidate.sh`
      comment (finder → lens); confirm `tiers.sh` needs no change.
- [x] 4.2 Gold: `REVISO_TIER=style REVISO_CMD_ARGS=--web` over the
      pair (TP matched with Source, clean silent), plus the TP once
      without `--web` (lens skipped, out of lane). Record run README +
      `docs/evals.md` row.

## 5. Release

- [x] 5.1 CHANGELOG 0.13.0, `plugin.json` 0.13.0.
- [ ] 5.2 Lint with CI globs; sync + archive on this branch; PR.
