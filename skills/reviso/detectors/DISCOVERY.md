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

## Rejected (and where the concern went)

| Candidate | Verdict | Reason |
| --- | --- | --- |
| Unused imports / dead symbols | ✗ → slop finder (`bugs` for hard cases) | Linter/typechecker territory per the exclusion list; dynamic access and side-effect imports make regexes FP-prone. |
| Comment restates code | ✗ → slop finder | Token-overlap heuristics misfire on legitimate doc comments; needs judgment. |
| AI-comment tells (banners, "This function…") | ✗ → slop finder | Style-dependent; legitimate in some codebases — convention-relative by nature. |
| Debug prints (`console.log`, `print`) | ✗ | Deliberate in CLIs/scripts; linter territory where unwanted. |
| `debugger;` statements | ✗ | `no-debugger` is an eslint default; exclusion list says skip. |
| TODO without ticket | ✗ → conventions finder | Team-convention dependent; only a finding if CLAUDE.md says so. |

## Validation

- **True positives:** synthetic fixture (conflict block in a `.ts`, `.only`
  and `fdescribe` in test files) — all flagged at the right `file:line`;
  markdown conflict tutorial and `=======` heading underline — not flagged.
- **False-positive sweep (2026-08-03):** detectors run over recent history
  diffs (`git log -p -U0 -n 300 --no-merges | awk -f detect.awk`) of
  `pica-studio`, `pica-api`, `pica-android`, `pica-ios`, `vyttle.com`, and
  this repo — **0 hits across ~1500 commits** (no FPs; no TPs expected in
  clean history). Any future FP demotes the detector per D5.

Re-run discovery when adding a detector; update both tables.
