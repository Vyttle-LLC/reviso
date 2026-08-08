## Reviso review — HEAD (detached) vs 7554b5e (1 commit, 32 files)

Found 3 issues:

1. **[P1][conf 95] Light-theme argument transposed — light theme regresses on two rules** — `app/assets/stylesheets/desktop/topic-post.scss:291`
   Failure: The commit's stated intent is to add a dark-theme branch; the light branch should be byte-identical to the old value. On these two rules the two arguments got swapped instead. `.topic-meta-data h5 a` was `scale-color($primary, 30%)` and is now `dark-light-choose(scale-color($primary, 70%), scale-color($secondary, 30%))` — in a light theme this bold username link jumps from near-body-text darkness to a washed-out 70% tint, a visible contrast regression. Mirror case at `app/assets/stylesheets/mobile/modal.scss:102`: `.custom-message-length` was `scale-color($primary, 70%)` and is now `dark-light-choose(scale-color($primary, 30%), ...)`, going the other way — much darker in light themes, and inconsistent with its own desktop counterpart `app/assets/stylesheets/desktop/modal.scss:94`, which correctly kept `(70%, 30%)`.
   Fix: `desktop/topic-post.scss:291` → `dark-light-choose(scale-color($primary, $lightness: 30%), scale-color($secondary, $lightness: 70%));`
   `mobile/modal.scss:102` → `dark-light-choose(scale-color($primary, $lightness: 70%), scale-color($secondary, $lightness: 30%));`
   (bugs / history — the light value is what `git show 7554b5e` had)

2. **[P2][conf 88] Three more light-theme values silently changed during the mechanical sweep** — `app/assets/stylesheets/desktop/user.scss:522`
   Failure: Same class of drift, smaller magnitude. `.name` in the user-preferences dropdown was `scale-color($primary, 30%)` and became `dark-light-choose(scale-color($primary, 50%), scale-color($secondary, 50%))` — it now renders identically to the `.title` line directly beneath it, collapsing a deliberate visual hierarchy. Same edit at `app/assets/stylesheets/mobile/user.scss:497`. And `app/assets/stylesheets/mobile/topic-post.scss:182` (`.topic-list h3`) went from `20%` to `(50%, 50%)`, while its desktop twin `desktop/topic-post.scss:321` correctly kept `(20%, 80%)` — so mobile and desktop headings now diverge. None of this is mentioned in the commit message.
   Fix: restore the original light values and derive the dark side as `100 - N`: `.name` → `(30%, 70%)` in both user.scss files; `mobile/topic-post.scss:182` → `(20%, 80%)`.
   (bugs / conventions — breaks the `light N% / dark (100−N)%` pairing every other hunk in this commit follows)

3. **[P2][conf 80] One `scale-color($primary, …)` missed by the sweep** — `app/assets/stylesheets/common/base/_topic-list.scss:115`
   Failure: `.topic-list.categories .category .badge-notification` is the only live unconverted `scale-color($primary, …)` declaration left in `app/assets/stylesheets/` after this commit, and it sits in a file the commit otherwise edited six times. In a dark theme `$primary` is light, so `scale-color($primary, $lightness: 50%)` on a transparent background over a dark surface leaves the category topic count near-illegible — exactly the bug the commit set out to fix.
   Fix: `color: dark-light-choose(scale-color($primary, $lightness: 50%), scale-color($secondary, $lightness: 50%));`
   (conventions)

Checked: bugs, conventions, history, comments, slop. Deterministic detectors did not run — `detectors/run.sh` needs a permission grant that wasn't given; re-run with approval if you want that layer.
Skipped: nothing — all 32 changed files reviewed. No `CLAUDE.md`/`AGENTS.md` exists in this repo.

Note: the remaining 110-odd converted lines all follow the `light N% / dark (100−N)%` rule correctly, and `dark-light-choose($light, $dark)` argument order matches `common/foundation/variables.scss:46`.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
