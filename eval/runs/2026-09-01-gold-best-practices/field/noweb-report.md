All seven lenses resolved. Report follows.

```text
## Reviso audit — audit-fixes vs main (11 commits, 23 files)

Found 5 issues:

1. [P1][conf 80] New submit-failure UI never fires on an HTTP error — src/components/SupportForm.tsx:49
   Failure: this change replaced the catch block's alert() with setFailed(true) and added a
   role="alert" recovery block, but fetch only rejects on network failure. Netlify Forms returns
   a non-2xx (the documented "form not yet detected after deploy" 400, a rate limit, a 500) as a
   resolved Response, so setSubmitted(true) runs, the user sees "Thanks for reaching out!", and the
   message was never delivered. The new failure UI is unreachable for the dominant failure mode.
   Fix: check `response.ok` after the await and setFailed(true) (skipping setSubmitted) on non-2xx.
   The missing status check itself predates the branch; what is new is the error path that claims
   to announce failures and doesn't.
   (bugs)

2. [P2][conf 85] VyttleMark is unconditionally aria-hidden, contradicting the rule this change added — src/components/marks/VyttleMark.tsx:16
   Failure: the diff swaps aria-label="Vyttle logomark" for aria-hidden="true" on every call site,
   and in the same diff adds to DESIGN.md:356 "Do mark a logomark aria-hidden when visible brand
   text sits beside it; announce it only when it stands alone." Nav.tsx:80-92 satisfies that rule;
   the homepage hero (src/app/page.tsx:23-26) renders the 80px mark alone under an h1 reading
   "Small by design", with no adjacent wordmark — so the code violates the rule it just wrote.
   Fix: make the treatment per-usage — keep aria-hidden in Nav, pass a label for the hero — or
   amend the DESIGN.md rule to say the mark is decorative everywhere.
   (bugs)

3. [P2][conf 85] eslint.config.mjs comment misstates what eslint-config-next bundles — eslint.config.mjs:4
   Failure: the comment says the default export "already bundles next/core-web-vitals,
   next/typescript, and jsx-a11y". It spreads @next/eslint-plugin-next's `recommended`, not
   `core-web-vitals` (which lives at the separate `eslint-config-next/core-web-vitals` entry point
   and upgrades no-html-link-for-pages and no-sync-scripts from warn to error), and wires only 6 of
   jsx-a11y's ~30 recommended rules, all at warn. A contributor trusts the comment and skips adding
   stricter rules; on a branch that is almost entirely a11y work, lint catches close to none of it.
   next/typescript is the one accurate clause.
   Fix: import "eslint-config-next/core-web-vitals" and/or spread jsx-a11y's recommended config, or
   correct the comment to name `recommended` and the 6-rule warn-only jsx-a11y subset.
   (comments)

4. [P2][conf 82] `dim` puts the atmosphere at z-index -10, contradicting DESIGN.md's z-0 plane and the Two-Plane Rule — src/components/ConicOrb.tsx:74
   Failure: the new `dim` branch sets an inline `zIndex: -10`, which beats the element's own `z-0`
   class, on the 7 pages that render `<ConicOrb dim />` (privacy, terms, support, four per-app
   privacy). DESIGN.md:243 still states flatly "The atmosphere plane (`z-0`)…", and DESIGN.md:257's
   Two-Plane Rule states "There are exactly two planes… Nothing lives between them." Neither doc
   mentions `dim`. The next person layering something on a policy page reasons from a stacking model
   the code no longer follows.
   Fix: document the `dim` variant in the Elevation section (z-index -10, opacity 0.22 light /
   0.5 dark, and why), or drop the inline override and give the dim pages a z-0 field with the
   content in its own stacking context.
   (conventions)

5. [P2][conf 80] DESIGN.md / design.json left stale for four of this change's own design changes — DESIGN.md:338
   Failure: the branch documents some of what it changed and not the rest, so the design contract
   now describes a site that no longer exists. Four confirmed gaps:
   - DESIGN.md:338 says the lightbox close button is "44×44, top-right, safe-area aware" — added by
     6c18aa7 on this branch, then contradicted by f07c739, which moved it to
     `bottom: calc(100% + 10px); right: 0` (above the image, no env() of its own).
   - design.json:194-199 and DESIGN.md:127-130 still show a single 36px theme toggle; ThemeToggle.tsx:35-44
     is now a 44px button wrapping a 36px span.
   - DESIGN.md:301's Bento Cells "content order" (badge pinned with mt-auto) doesn't cover the new
     featured variant, which drops mt-auto and adds a description column (BentoCell.tsx:122,144-156).
   - The new --amber-text token (globals.css:68,107) is undocumented, while DESIGN.md:159 still names
     #B8802E as the light-mode interactive amber — the value globals.css:65-68 now says fails 4.5:1
     as text.
   Fix: one pass over DESIGN.md and .impeccable/design.json for these four before opening the PR.
   (conventions, history)

Checked: deterministic detectors, conventions, bugs, history, prior reviews, comments, slop.
Not checked: best-practices (no --web).
Skipped: .impeccable/critique/2026-07-24T18-41-40Z__src-app-page-tsx.md (untracked generated artifact).
```

One thing worth knowing that isn't a finding: the prior-reviews lens found this branch's 11 commits are word-for-word identical to already-merged PR #21 (`83a37b1`) — so this may be a replay rather than new work.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
