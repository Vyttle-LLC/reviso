Detector suite: the `run.sh` invocation was declined at the permission prompt, so deterministic detectors did not run. Everything below is my own single-pass review.

```text
## Reviso review — HEAD (detached) vs cbebe01 (0 commits, 1 file)

No issues found.

Checked: bugs, conventions, history, comments, slop. Deterministic detectors NOT run (permission declined).
Skipped: nothing.
```

Notes on what I looked at in `src/services/notification-preferences.ts` (new, untracked, 63 lines) and why nothing cleared the bar:

- **Quiet-hours merge (`:48-53`)** — the explicit `!== undefined` ternaries are correct; `??`/`||` here would have silently dropped `0` (midnight). This is the right shape.
- **Channel merge (`:31-46`)** — defaults seeded first, `saved` replaces wholesale, `overrides` shallow-merges onto the existing entry. The asymmetry is harmless because `Partial<UserPreferences>` is shallow, so array elements are always complete `NotificationChannel` objects. Defaults are spread on insert, so `DEFAULT_CHANNELS` is never aliased or mutated. Map insertion order gives stable output ordering.
- **`userId` precedence (`:26`)** — `saved` wins over `overrides`, the reverse of `timezone` at `:27`. Plausibly deliberate (an override shouldn't reassign identity), and with no callers in the repo I can't verify it as wrong. Scored below the gate.
- **`var` / `function (ch)` / verbose `x !== undefined && x.y !== undefined`** — style, and the repo has no `CLAUDE.md`, `AGENTS.md`, lint config, or any other tracked source file to establish a norm to drift from. Slop findings must be convention-relative, so there's nothing to anchor them to; linter/formatter territory is excluded regardless.

No commit messages, ticket ID, or conventions files exist on this branch — the change is entirely untracked working-tree content against an empty base.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
