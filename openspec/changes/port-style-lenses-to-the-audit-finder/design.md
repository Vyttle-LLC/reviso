# Design — port-style-lenses-to-the-audit-finder

## Context

Since 0.5.0 the audit's finders return evidence and the orchestrator
judges. `/reviso:style` (0.6.0+) is a single session doing both. The
style lenses were deliberately incubated in style first (0.7.0 proposal,
"nailing it here is cheaper and safer than spreading it across three
surfaces"). This change is the promotion step that decision implied.

## Goals / Non-Goals

**Goals:**

- The audit gate applies every style lens that has proven precise.
- No drift between the finder's lens text and style.md's.
- Finder/orchestrator split preserved: evidence in the agent, judgment
  in the orchestrator.

**Non-Goals:**

- `/reviso:review` — stays P0; inner loop.
- Splitting the slop finder into several agents (one per family).
  Revisit only if the single finder's context blows up on large diffs.
- Changing any lens's definition. A lens that needs changing to port is
  not proven; it stays in style until it is.

## Decisions

### D1 — Admission rule, not a fixed list

A style lens is portable when: (a) it has been in a released version
for at least one minor release, (b) its gold TP/clean pair holds, and
(c) no `--reason` feedback payload or field report against it has been
adjudicated a true false positive. The tasks file records which lenses
met the rule at implementation time; the spec names the rule. This
avoids re-proposing every time a lens matures. Alternative rejected:
port all sixteen at once — 0.8.0/0.9.0 lenses would have zero field
time.

### D2 — Lens text is shared by reference, not duplicated

`commands/style.md` stays the source of each lens's wording;
`agents/reviso-finder-slop.md` carries the same text with the
finder-specific framing (return everything, count occurrences, do not
gate). The duplication item already lives under this rule ("must not
drift"); the ported lenses join it. A tasks item checks the two files
against each other before release.

### D3 — Style-local gates move to the audit orchestrator

The absolute comments bar, the placeholder-text item, `no-baseline`,
and `no-search` are applied in `commands/audit.md` Stage 4 exactly as
style.md Step 4 applies them. The finder still returns a comments
candidate without a baseline — the orchestrator drops it. The shared
exclusion list stays untouched (same carve-out shape as 0.7.0 D2).

### D4 — One finder, per-lens ledger sub-rows

The finder remains one Task returning one array; each candidate
already carries its lens name in `evidence`. The orchestrator records
`slop` as before plus one sub-row per ported lens so the coverage block
can name them. A finder that returns `[]` yields `returned, 0` for
every sub-row; a finder that never returns yields `no result` for all.

### D5 — Severity: audit's band for deterministic, style's for ported

Ported lens candidates keep the style band (P2, P1 when misleading,
never P0) — they are the same findings, and "nothing purely stylistic
blocks a merge" holds in the gate too. Bugs the audit's other finders
surface keep their own bands.

## Risks / Trade-offs

- [Audit run cost rises with finder scope] → measured on the field
  smoke test against a 0.9.0 audit on the same branch; if the slop
  finder dominates, the per-family split in Non-Goals is the next
  change.
- [Two copies of lens text drift] → D2's pre-release diff check; the
  duplication item has held under this rule since 0.6.0.
- [A lens that proved clean in style fires differently in a finder
  that cannot gate] → the orchestrator's gate is the same rubric; gold
  run over the `slop-*` cases at `REVISO_TIER=audit` must match the
  style-tier results before release.

## Migration Plan

Additive. 0.10.0. Users who ran `style` then `audit` get the ported
findings once, from the audit; style remains the faster style-only
pass.

## Open Questions

- Whether a "reject" adjudication path exists for the D1 admission rule
  beyond the feedback payloads — today field FPs reach the repo as
  issues or memory, not a ledger. Default: a `docs/lens-status.md`
  table recording each lens's admission evidence, maintained by this
  and future port changes.
