# Tasks — add the style verb

## 1. The command

- [x] 1.1 Write `commands/style.md` frontmatter: description, argument
      hint (`--base`, `--out`, `--explain`), `model: opus`, and the same
      read-only `allowed-tools` set as `commands/review.md` (no Edit/Write/
      NotebookEdit, no write-capable Bash patterns; the `gh` patterns are
      dropped — no prior-reviews lens here)
- [x] 1.2 Port Step 1 (mock-PR assembly) and Step 2 (deterministic
      detectors) from `commands/review.md` byte-for-byte in behavior:
      same git sequence, same flag handling, same coverage-ledger rules
- [x] 1.3 Write Step 3 with the five style lenses: anti-slop P0 set and
      duplication copied verbatim from `review.md` (spec: the three
      surfaces must not drift), conventions (code-shaped rules only —
      drop review.md's branch-shape and doc-staleness clauses), and the
      two new lenses per design D3
- [x] 1.4 Encode the calibration rules in the two new lenses: drift needs
      ≥2 cited `file:line` examples of the established pattern; outlier
      length must name the comparable units and their sizes; absolute
      thresholds banned; established repo style is never a finding
- [x] 1.5 Write the no-bug-hunting scope note: noticed bugs never ship;
      the report directs users to `/reviso:review` / `/reviso:audit`
- [x] 1.6 Port Step 4 (self-verify: exclusion list, rubric, drop <80) and
      Step 5 (report: dedupe, P2 floor, 8-finding cap, clean-report and
      broken-lens wording, `--explain` diagnostics) from `review.md`,
      adding the style severity band (P2 default, P1 only when actively
      misleading or already-diverged copies, never P0) and a `no-baseline`
      drop reason for D3's citation gate
- [x] 1.7 Wire feedback: add `style` to `build-payload.sh`'s `--command`
      allowlist (usage comment + `oneof`); style.md's Step 6 maps its
      lenses to existing schema dimensions (drift/length/duplication →
      `slop`), so the lens allowlist and docs/feedback.md need no change

## 2. Specs

- [x] 2.1 Apply the review-command delta to
      `openspec/specs/review-command/spec.md`: replace the "Two tiers"
      requirement with "Three verbs", update the spec's Purpose line to
      name all three commands
- [x] 2.2 Create `openspec/specs/style-command/spec.md` from this change's
      delta spec

## 3. Docs and release

- [x] 3.1 Update `README.md` and `docs/` where the command roster is
      described: what `/reviso:style` is for, and when to reach for it vs
      review/audit
- [x] 3.2 Bump `.claude-plugin/plugin.json` to 0.6.0 and add a CHANGELOG
      entry
- [x] 3.3 Grep the repo for stale "two commands"/"two tiers" phrasing and
      fix any the roster change orphaned — fixed docs/feedback.md, and
      generalized review-command's "both commands" contracts to "every
      review command" (delta expanded; style-command spec slimmed to the
      style-specific requirements). CHANGELOG history and gold-eval's
      "two tiers" (review vs audit measurement tiers) left as accurate

## 4. Verification

- [x] 4.1 Run `/reviso:style` on this branch's own diff — confirm:
      no subagents spawned, no writes without `--out`, every finding
      carries a cited repo baseline, ledger rows for all five lenses plus
      deterministic. All held; the run also shipped one real P1 against
      this change (style.md's duplication item claimed unqualified
      identity with the audit finder, whose post-0.5.0 semantics gate at
      the orchestrator) — fixed by scoping the claim to the bar/protocol
      in style.md and both style-command specs
- [x] 4.2 Run it on a known-slop fixture (e.g. an eval corpus case with
      slop labels) — confirm the anti-slop and duplication findings match
      what `/reviso:review` ships for the same diff. Ran on termic-162,
      the duplication lens's seed exemplar, judged blind against the
      hand-authored label rather than a fresh `/reviso:review` run (the
      label is what that lens was calibrated on): the 7-site collision
      predicate shipped as one consolidated P2 at conf 92 with every
      occurrence cited and the helper named, matching the label; a second
      real 7-copy e2e duplication also shipped; below-bar candidates
      stayed silent
- [x] 4.3 Negative test: a diff containing an obvious bug but clean style —
      confirm the report ships no bug finding and points at the sibling
      verbs. Ran on a fixture built from eval's bug-off-by-one-001: the
      reviewer noticed the `<=` off-by-one, followed the no-bug-hunting
      rule (no candidate, no mention beyond the scope line), and correctly
      gated its two style candidates (exclusion-list, rubric-score)
- [x] 4.4 `lint` passes (markdownlint-cli2 + lychee) on all touched files
      — 0 issues / 18 links OK
- [x] 4.5 File the follow-up issues for design OQ1 (extract the shared
      slop-lens text into `skills/reviso/references/`) and OQ2
      (style-labeled eval cases) — filed as VYT-152 and VYT-153 in the
      new Linear "Reviso" project
