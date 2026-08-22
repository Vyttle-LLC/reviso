# Tasks — port-style-lenses-to-the-audit-finder

## 1. Admit lenses

- [ ] 1.1 Apply D1 to every style lens: list each with release version,
      gold TP/clean result, and any adjudicated FP; record the admitted
      set in `docs/lens-status.md` (new, per the open question).
- [ ] 1.2 Confirm the admitted set with Michael before porting — the
      list is the change's scope.

## 2. Port to the finder

- [ ] 2.1 Add each admitted lens to `agents/reviso-finder-slop.md` with
      the finder framing (D2): same definition and evidence protocol as
      `commands/style.md`, plus "return it either way, the orchestrator
      gates" where style.md says "drop".
- [ ] 2.2 Diff the lens definitions between the two files and resolve
      every wording difference that is not finder framing.

## 3. Orchestrator

- [ ] 3.1 `commands/audit.md` Stage 4: add the style-local gates (D3) —
      comments bar with written-convention override, placeholder-text
      absolute item, `no-baseline`, `no-search`.
- [ ] 3.2 Ledger: per-lens `slop` sub-rows (D4); Stage 6 coverage block
      and `--explain` example updated; Step 7 feedback mapping carries
      the ported lenses to the `slop` dimension.
- [ ] 3.3 Severity paragraph: ported lens candidates keep the style band
      (D5).

## 4. Eval

- [ ] 4.1 Mark the `slop-*` synthetic cases in-lane for
      `REVISO_TIER=audit` in `eval/runners/tiers.sh` / corpus README for
      the ported lenses only.
- [ ] 4.2 Gold run at `REVISO_TIER=audit` over the ported lenses' cases:
      results must match the style-tier run case for case.
- [ ] 4.3 Field smoke test: `/reviso:audit` on a real branch, compared
      with a 0.9.0 audit on the same branch — findings gained, run time,
      and the ledger's sub-rows.

## 5. Docs and release

- [ ] 5.1 README / `docs/` lens enumerations for audit; record eval
      results.
- [ ] 5.2 CHANGELOG 0.10.0, `plugin.json` bump.
- [ ] 5.3 Sync the delta spec and archive this change on the feature PR.
