All evidence in. Applying the gate.

## Reviso audit — audit-fixes vs origin/main (11 commits, 24 files)

Found 4 issues:

**1. [P2][conf 88] Tabbing past the last menu link puts focus behind the open overlay — src/components/MobileMenu.tsx:69**
Failure: keyboard user opens the mobile menu, tabs past "Support" → focus exits the panel onto the first focusable element in `<main>`, which is still in the DOM (no `inert`/`aria-hidden`) and sits under a 92%-opaque `--surface-glass` + 24px-blur overlay at z-40. Focus is reachable but invisible, with body scroll locked. Nav's sibling disclosure already guards this at Nav.tsx:32-36 with a `focusout` auto-close; MobileMenu has none.
Fix: add the same `focusout` handler — close when `relatedTarget` leaves the panel. Do **not** add a Tab trap: DESIGN.md:324/354 deliberately specifies this as a disclosure, not a modal, and the ARIA disclosure pattern doesn't trap. Recoverable today only because the Escape listener is document-scoped.
(slop; functional half of a duplication candidate)

**2. [P2][conf 82] VyttleMark is unconditionally aria-hidden, contradicting the rule the same commit wrote — src/components/marks/VyttleMark.tsx:16**
Failure: 6c18aa7 replaced `aria-label="Vyttle logomark"` with a hardcoded `aria-hidden="true"` **and** added DESIGN.md's "announce it only when it stands alone." Nav.tsx:81 satisfies the rule (wordmark adjacent); the homepage hero at page.tsx:23 does not — the mark sits alone in its own div, and the component has no prop to differentiate. Impact is limited: `<title>` "Vyttle — Small by design", the Nav wordmark, and hero prose all still announce the brand, so nothing is silenced site-wide.
Fix: either give VyttleMark a `decorative`/`label` prop and pass the labeled variant from the hero, or relax the DESIGN.md rule to match the shipped behavior. The mismatch is the defect; both directions resolve it.
(conventions, bugs, history, prior-reviews, comments — five lenses converged)

**3. [P2][conf 82] DESIGN.md never documents the `--amber-text` token or ConicOrb's `dim`/static gate — DESIGN.md:159**
Failure: this change edited DESIGN.md extensively but left the contradicting passages. DESIGN.md:159 still says light-mode amber "deepens to #B8802E for contrast" and :284 says prose links are "bare amber text" — a contributor following that colors light-mode text with `--amber-accent` at 2.4:1, reintroducing exactly what 989dbd7/77bcdd6 fixed. Grep finds no mention of `--amber-text` anywhere in DESIGN.md. Separately, "The Atmosphere" (:328) documents the signature component with no mention of the `dim` prop now used on 7 pages, nor the desktop-only animation gate.
Fix: state the two-tier amber rule (`--amber-accent` non-text ≥3:1, `--amber-text` for any amber word ≥4.5:1; light prose links use `--text-primary` + amber underline), and add the `dim` variant and mobile-static gate to The Atmosphere.
(conventions; two related doc gaps consolidated)

**4. [P2][conf 80] Policy-page shell duplicated byte-identically across 7 files — src/app/privacy/page.tsx:15**
Failure: `<ConicOrb dim /><Nav /><main id="main" tabIndex={-1} className="pt-32 pb-16 px-6 md:px-12 focus:outline-none">` is identical in privacy, terms, support, and the four per-app privacy pages. This branch paid the fan-out tax twice already — 91e21e9 hand-added `<ConicOrb dim />` to all 7, then 6c18aa7 hand-added `id="main" tabIndex={-1}` to the same 7. `id="main"` is a live contract (layout.tsx's skip link targets it), so a missed file silently breaks that page.
Fix: extract a small `PageShell({ dim, children })`. AppPageLayout can't be reused as-is — it requires an `app` prop and renders a hero. A nested `layout.tsx` would also work; none exists today.
(slop; 7 occurrences)

Checked: deterministic detectors, conventions, bugs, history, prior reviews, comments, slop, best-practices.
Skipped: `.impeccable/design.json`, `.impeccable/critique/2026-07-24T18-41-40Z__src-app-page-tsx.md` (untracked), DESIGN.md prose hunks.

```
--- explain: pipeline diagnostics (not review findings) ---
Finders: conventions 6, bugs 3, history 1, prior-reviews 2, comments 3,
slop 3, best-practices 2, deterministic 0.

Candidates before the gate (20):
  [slop]            MobileMenu.tsx:69          score 88  reported
  [conventions]     VyttleMark.tsx:16          score 82  reported
  [bugs]            VyttleMark.tsx:16          score 82  merged into above
  [history]         VyttleMark.tsx:16          score 82  merged into above
  [prior-reviews]   VyttleMark.tsx:16          score 82  merged into above
  [comments]        VyttleMark.tsx:16          score 82  merged into above
  [conventions]     DESIGN.md:159              score 82  reported
  [conventions]     DESIGN.md:328              score 80  merged into above
  [slop]            privacy/page.tsx:15        score 80  reported
  [comments]        globals.css:68             score 62  dropped: rubric-score
  [conventions]     DESIGN.md:129              score 62  dropped: rubric-score
  [slop]            Nav.tsx:202                score 60  dropped: rubric-score
  [comments]        MobileMenu.tsx:40          score 40  dropped: rubric-score
  [bugs]            MobileMenu.tsx:69          score 35  dropped: rubric-score
  [best-practices]  ThemeToggle.tsx:13         score 20  dropped: exclusion-list
  [best-practices]  MobileMenu.tsx:40          score 20  dropped: exclusion-list
  [prior-reviews]   AppPageLayout.tsx:106      score 15  dropped: exclusion-list
  [conventions]     specs/2026-03-21-...md:49  score 15  dropped: pre-existing
  [bugs]            SupportForm.tsx:39         score  0  dropped: pre-existing
  [conventions]     CLAUDE.md:12               score  0  dropped: pre-existing

Web (6 searches, 5 fetches, bound not hit):
  next.js 16 data-scroll-behavior smooth html attribute
  eslint-config-next 16 flat config native array documentation
  eslint-plugin-react-hooks set-state-in-effect rule
  nextjs.org docs eslint flat config eslint-config-next migration guide
  react.dev useSyncExternalStore avoid hydration mismatch setState effect mounted pattern
  "set-state-in-effect" eslint-disable exception ref lazy initialization documentation
  https://nextjs.org/docs/messages/missing-data-scroll-behavior
  https://react.dev/reference/eslint-plugin-react-hooks
  https://nextjs.org/docs/app/guides/upgrading/version-16
  https://nextjs.org/docs/app/api-reference/config/eslint
  https://react.dev/reference/eslint-plugin-react-hooks/lints/set-state-in-effect
```

Two drops worth a word since you asked for diagnostics: `SupportForm.tsx:39` never checks `response.ok`, so a non-2xx Netlify response still shows "Thanks for reaching out!" — real, but blame puts it at 7943504, pre-merge-base, so the gate scored it pre-existing. The two `set-state-in-effect` candidates cited a live rule at the right version, but both disables are block-scoped with written rationale and the evidence showed no flicker reproduces (both components render a placeholder/null until mounted), so they hit the "explicitly silenced" exclusion.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
