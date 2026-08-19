# Detector discovery (OQ1)

The bar (design D5): a detector ships only if it is **FP-free by
construction**. Candidates were evaluated against that bar and against the
false-positive exclusion list's "a linter would catch it" principle, then
swept over recent Vyttle repo history (see Validation below).

## Shipped

| Detector | Construction | Why it clears the bar |
| --- | --- | --- |
| `conflict` — committed merge-conflict markers | All three markers (`<<<<<<<` plus label, bare `=======`, `>>>>>>>` plus label), in order, in the change's added lines. Suppressed in markdown. | RST/markdown `=======` underlines can't match (no arrows). Docs teaching conflict resolution are excluded via the markdown suppression. Linters don't cover non-code files, where these actually survive. |
| `testfocus` — focused tests committed | `.only(` on `it/test/describe/context`, or `fit(`/`fdescribe(`, in test-path files only. | Focusing is deliberate *locally* and near-universally unintended *committed*; the failure (suite silently skipped in CI) is mechanical. `jest/no-focused-tests` exists but is not on by default in typical configs — checked absent in the swept repos. |
| `placeholder` — placeholder text committed | Case-insensitive curated phrases in added non-markdown lines: "in a real implementation/app/application/system/project", "in production(,) you would", "a real implementation would". Suppressed in markdown and in `examples?/demos?/samples?/fixtures?` paths. | The phrases have one meaning: unimplemented code presented as implemented — no repo's norm is a stand-in that lies. Teaching material legitimately narrates stand-ins, hence the markdown and example-path suppressions (same shape as `conflict`'s markdown rule). No linter covers prose in comments. |

## Rejected (and where the concern went)

| Candidate | Verdict | Reason |
| --- | --- | --- |
| Unused imports / dead symbols | ✗ → slop finder (`bugs` for hard cases) | Linter/typechecker territory per the exclusion list; dynamic access and side-effect imports make regexes FP-prone. |
| Comment restates code | ✗ → slop finder | Token-overlap heuristics misfire on legitimate doc comments; needs judgment. |
| AI-comment tells (banners, "This function…") | ✗ → slop finder | Style-dependent; legitimate in some codebases — convention-relative by nature. |
| Debug prints (`console.log`, `print`) | ✗ | Deliberate in CLIs/scripts; linter territory where unwanted. |
| `debugger;` statements | ✗ | `no-debugger` is an eslint default; exclusion list says skip. |
| TODO without ticket | ✗ → conventions finder | Team-convention dependent; only a finding if CLAUDE.md says so. |
| "would/will go here", "logic goes here" | ✗ → AI-tells lens (style command) | 0 sweep hits, but the construction can't exclude legitimate empty-state UI copy ("Your saved recipes will go here") — a string literal and a comment are indistinguishable to a regex. |
| "this is a simplified version/implementation" | ✗ → AI-tells lens (style command) | Can be an honest description of a deliberate simplification ("simplified version of Dijkstra assuming unit weights") — judging honesty needs the code. |
| Changelog-style comments ("// Fixed bug where…") | ✗ → AI-tells lens (style command) | Can be a legitimate historical note; convention-relative by nature. |
| Temporal/comparative naming (`new*`, `enhanced*`, `*2`) | ✗ → AI-tells lens (style command) | `newUser` is usually just a new user; drowning in FPs by construction. |
| Emoji in code files | ✗ → AI-tells lens (style command) | 2026-08-19 sweep hit vendored localization fixtures — legitimate user-facing non-ASCII text is the normal case, not the exception. |
| Duplicate-run assist (hint channel, not a finding source) | ✗ → slop finder item 5 | Normalized added lines recurring ≥3× in the diff. Prototyped against the duplication lens's own seed case (2026-08-08): missed the target predicate — 7 occurrences, only 2 byte-identical, the rest differing by receiver/argument or wrapped mid-expression — while emitting 9 hints that were all test scaffolding. Duplication worth extracting is similar *under renaming*, a token-level property; line matching sees only the least interesting instances. The finder's distinctive-identifier grep protocol covers it instead. A token-n-gram version is the one that could clear the bar. |

## Validation

- **True positives:** synthetic fixture (conflict block in a `.ts`, `.only`
  and `fdescribe` in test files) — all flagged at the right `file:line`;
  markdown conflict tutorial and `=======` heading underline — not flagged.
- **False-positive sweep (2026-08-03):** detectors run over recent history
  diffs (`git log -p -U0 -n 300 --no-merges | awk -f detect.awk`) of
  `pica-studio`, `pica-api`, `pica-android`, `pica-ios`, `vyttle.com`, and
  this repo — **0 hits across ~1500 commits** (no FPs; no TPs expected in
  clean history). Any future FP demotes the detector per D5.
- **`placeholder` discovery (2026-08-19):** phrase candidates swept over
  recent history (same command shape, 300 commits each) of `pica-studio`,
  `pica-api`, `pica-android`, `pica-ios`, `pica-puzzle-library`,
  `pica-qa-tool`, `vyttle.com`, `reviso-api`, `reviso-action`, and this
  repo — **0 phrase hits across ~2700 commits**. True positives: synthetic
  fixture with all three phrase families in `.ts`/`.py` — flagged at the
  right `file:line`; the same phrase in markdown and under `examples/`,
  and an innocuous empty-state UI string — not flagged. The emoji
  candidate's sweep hit vendored localization fixtures in `reviso-api`,
  confirming its rejection.

Re-run discovery when adding a detector; update both tables.
