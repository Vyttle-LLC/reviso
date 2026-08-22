# Port style lenses to the audit finder

## Why

`/reviso:audit` is the pre-PR gate, but its anti-slop finder still runs
the original five-item P0 set while `/reviso:style` has grown to sixteen
lenses. A branch that passes the audit can still carry dead weight,
tests that cannot fail, or placeholder text — and the user has to know
to run a second verb to hear about it. Once the style lenses have held
precision through two releases of gold runs and field use, the proven
ones belong in the gate too.

## What Changes

- `reviso-finder-slop` grows from the P0 set to the **proven style lens
  set**: every style lens whose gold run and field feedback show no
  confirmed false positive since it shipped. The candidate list at
  proposal time is the 0.7.0 five (comments, over-engineering, dead
  weight, test slop, AI tells) plus whichever 0.8.0/0.9.0 lenses have
  cleared the same bar by implementation time; the design fixes the
  admission rule, not the list.
- The finder keeps its contract: it returns every evidenced candidate
  with the lens's evidence protocol satisfied (recorded search, absence
  citation, quoted tell, lockstep citation) and never gates. The
  orchestrator applies the style-local rules — the absolute comments bar
  and placeholder-text item, the no-baseline / no-search drops — at its
  gate, exactly as `/reviso:style` Step 4 does.
- The audit's ledger gains one `slop` sub-row per ported lens so the
  coverage block can say which style lenses the gate applied; the
  finder's single Task is unchanged (one agent, many lenses).
- The shared exclusion list is still untouched; the comments-bar
  carve-out lives in the audit orchestrator, as it lives in style.md.
- Gold: the `slop-*` synthetic cases become meaningful for
  `REVISO_TIER=audit` too, and the corpus README's "style-only" note is
  relaxed for the ported lenses.

Out of scope: `/reviso:review` stays at the P0 set (inner loop, speed
over coverage); lenses that have not cleared the admission bar; any
change to the duplication bar.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `review-pipeline`: the anti-slop finder's scope expands to the proven
  style lens set with per-lens evidence protocols; the orchestrator
  gate gains the style-local rules; the ledger carries per-lens slop
  sub-rows.

## Impact

- `agents/reviso-finder-slop.md` — ported lens text (shared wording with
  `commands/style.md`; the two must not drift, same rule the duplication
  item already carries).
- `commands/audit.md` — Stage 4 gate additions, ledger sub-rows, Stage 6
  coverage block, `--explain` example, feedback mapping.
- `eval/corpus/README.md`, `eval/runners/tiers.sh` — ported lenses
  in-lane for the audit tier.
- `openspec/specs/review-pipeline/spec.md` via the delta.
- `CHANGELOG.md` 0.10.0, `plugin.json` bump.
