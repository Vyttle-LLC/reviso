# Give style its own confidence rubric

## Why

**`/reviso:style` scores style findings on a rubric written for bugs, and
honest style findings cannot clear it.** The shared
`skills/reviso/references/confidence-rubric.md` anchors its bands on
impact: 75 is "very likely a real issue that will be hit in practice…
very important and will directly impact the code's functionality", and 50
is "a real issue, but it might be a nitpick… relative to the rest of the
change, it's not very important". A verified style finding — a comment
that restates its code, a `Manager` in a `Service` repo, an export with
no external caller — is by definition not going to impact functionality
and is, in the rubric's own words, a 50. The gate is 80. What survives is
the handful of findings that happen to read as bug-shaped (a test that
cannot fail, a comment that lies) or that CLAUDE.md names explicitly.

The measured shape in the field: on real branches the command reports
about one finding per run, while a bug-hunting review of the same branch
reports about ten, at a comparable token cost — sixteen lenses reading
full files and history to ship one line. The eval corpus cannot see this:
its style cases are seeded with blatant slop that scores 85–100 under any
wording of the rubric, so every acceptance run to date reads 100% recall
while the field yield says otherwise. On the one multi-lens gold case
with `--explain`, the four drops at 40–72 were all correct — precision is
not the problem; the problem is that the corpus never exercises the
"verified but not important" band that dominates real code.

The sibling change `recalibrate-the-confidence-rubric` diagnosed the same
conflation — "is this real" and "does this matter" riding one number —
for the review/audit pipeline, with three recorded data points (drops at
68 and 60, an overscore at 85). It answers with a two-axis score, which
is right for bugs, where importance is a legitimate input. Style has no
importance axis at all: the lens protocols already decide what is worth
calling out (two same-language examples, a quoted tell, a recorded
search), and the severity band already carries how much it matters
(P1 misleads, P2 otherwise). Charging importance a second time at the
gate is what empties the report.

## What Changes

- **A style-specific rubric**, `skills/reviso/references/
  style-confidence-rubric.md`, on which confidence measures **evidence
  quality only**: did the candidate satisfy its lens's evidence protocol,
  does it hold against the real code, is the baseline unambiguous, is the
  fix concrete. Importance, frequency, and "would a senior engineer
  bother" are named as inputs the rubric does not take — the lens
  protocols and the severity band already own them. Bands are ranges,
  not the recipe's point anchors, with a revision identifier.
- **`/reviso:style` Step 4 scores on the style rubric**, not the shared
  one. The 80 gate, the silent drop, the P2 floor, the cap of 8, and the
  `--explain` record are unchanged; the feedback payload's confidence
  buckets (`80s` / `90s` / `100`) still cover every score the new bands
  produce.
- **The exclusion list's importance-shaped entries are read through the
  lens protocols in the style lane.** "Pedantic nitpicks a senior
  engineer wouldn't call out" and "general code quality… poor
  documentation" match a style candidate only when it fails its lens's
  protocol; a candidate that satisfies the protocol is, by construction,
  what a senior engineer calls out in a style review. The shared list
  file is untouched — this is a style-command-local reading, like the
  existing comments-lens carve-out.
- **Field measurement, since the corpus is blind here.** The change ships
  with a numbers-only funnel recorded from `--explain` on real branches
  before and after: candidates, reported, and drops by reason
  (`rubric-score`, `no-baseline` / `no-search` / `no-quote`,
  `exclusion-list`, `pre-existing`). That table is what answers the
  question this change was opened on — gate too high, or lenses not
  generating — and decides whether the evidence protocols themselves
  need a follow-up.
- **Non-goals:** the 80 threshold does not move; the lens evidence
  protocols (the two-example bar, the recorded search) do not loosen;
  the shared rubric and the review/audit gate are untouched — those are
  `recalibrate-the-confidence-rubric`'s.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `style-command`: the self-verification gate scores on a style-specific
  rubric that measures evidence quality and takes no importance input;
  the importance-shaped exclusion-list entries are satisfied by the lens
  protocols; the shared harness is otherwise reused unchanged. The
  requirement "The style command reuses the shared harness unchanged" is
  renamed and rewritten accordingly, and a new requirement states what
  the style rubric scores.

## Impact

- `skills/reviso/references/style-confidence-rubric.md` — new.
- `commands/style.md` — Step 4 (which rubric, how the exclusion list
  reads), Step 6 (bucket mapping confirmed against the new bands).
- `skills/reviso/SKILL.md` — lists the new reference and states which
  command uses which rubric.
- `CHANGELOG.md`, `.claude-plugin/plugin.json` — 0.10.0.
- `docs/evals.md` — the field funnel table, the 0.10.0 style acceptance
  row, and a note that style candidate scores before and after 0.10.0
  are not comparable.
- `eval/runs/` — the 0.10.0 style gold sweep (expected-clean cases must
  stay silent; that is the precision tripwire).
- Independent of `recalibrate-the-confidence-rubric`: different file,
  different command, no shared requirement text. Report-only unchanged;
  `git commit -s`, one concern per PR, `markdownlint-cli2` and `lychee`
  must pass.
