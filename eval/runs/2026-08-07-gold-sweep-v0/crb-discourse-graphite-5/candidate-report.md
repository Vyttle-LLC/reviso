Detector suite could not run — the `sh .../detectors/run.sh` call was not approved, so this pass is model-review only.

## Reviso review — HEAD (detached) vs 98fa098e6f (1 commit, 5 files)

Found 4 issues:

1. **[P1][conf 85]** `@include order(2)` on `.extra-info-wrapper` is inert — it is not a flex child of `.contents` — `app/assets/stylesheets/common/base/topic.scss:30`
   Failure: `{{header-extra-info}}` (`components/header-extra-info.js.es6`) declares no `tagName`/`classNames`, so Ember emits an anonymous `<div class="ember-view">` between `.contents` and `.extra-info-wrapper` (`templates/header.hbs:93-95`, `components/header-extra-info.hbs:1`). That anonymous div is the flex item, so `order`/any flex sizing on `.extra-info-wrapper` never applies. The real damage is truncation: under the old float layout `.extra-info-wrapper` was a normal block (with `overflow: hidden`, `desktop/topic-post.scss:518`) that filled the space between the floated `.title` and `.panel`, so `.topic-link { white-space: nowrap; text-overflow: ellipsis }` (`desktop/topic-post.scss:532-538`) clipped long titles. Now the anonymous flex item defaults to `min-width: auto`, whose content-based minimum is the full nowrap title width — so on a topic with a long title the docked header stops ellipsizing and instead pushes `.panel` (search / hamburger / avatar) right, past `.wrap`.
   Fix: give the component a real element — `classNames: ['extra-info-wrapper']` + `tagName: 'div'` on `header-extra-info.js.es6` and drop the wrapper `<div>` from its template — then on `.extra-info-wrapper` add `flex: 1 1 auto; min-width: 0;` alongside `@include order(2)`. `min-width: 0` is required regardless; `order` alone will not restore truncation.
   (bugs)

2. **[P2][conf 88]** Removing `float: right` from `.panel` breaks the server-rendered ERB header — `app/assets/stylesheets/common/base/header.scss:35`
   Failure: `app/views/application/_header.html.erb:3-19` nests `.contents > .row > {.title.span13, .panel}`. `.row` is not a flex container, so `.panel`'s new `margin-left: auto` and `@include order(3)` do nothing, while the removed `float: right` was what put it at the header's right edge. `.title.span13` still floats via `[class*="span"] { float: left }` (`vendor/bootstrap.scss:36-38`), so the anonymous login button now renders immediately beside the logo instead of top-right. This partial is rendered by `layouts/application.html.erb:40` (pre-boot paint and crawler view) and `layouts/no_ember.html.erb:22` (permanent for non-Ember pages).
   Fix: either update `_header.html.erb` to match the Ember DOM (drop the `.row`/`.span13` wrapper so `.title` and `.panel` are direct children of `.contents`), or scope the flex rules to `.d-header .contents > .row` as well.
   (bugs, history)

3. **[P2][conf 85]** `.small-action-desc` padding change orphans its mobile compensating overrides — `app/assets/stylesheets/common/base/topic-post.scss:280`
   Failure: `padding: 0.5em 0 0.5em 4em` → `padding: 0 1.5%` drops ~50px of left padding, but `mobile/topic-post.scss:520-522` still applies `.custom-message { margin-left: -40px }`, which existed only to pull the custom message back out of that 4em indent. On mobile, a small action with a custom message (e.g. a close/archive note) now hangs ~40px to the left of its own container, overlapping or clipping under `.topic-avatar`. `mobile/topic-post.scss:517-519` (`p { padding-top: 0 }`) is likewise now dead, since `> p { padding-top: 4px }` was deleted at `topic-post.scss:303`.
   Fix: remove `.custom-message { margin-left: -40px }` and the now-dead `p { padding-top: 0 }` from `mobile/topic-post.scss:516-523` as part of this change.
   (bugs, conventions)

4. **[P2][conf 82]** `.small-action` made a flex container without sizing `.small-action-desc`, so `button { float: right }` stops right-aligning — `app/assets/stylesheets/common/base/topic-post.scss:264`
   Failure: `.small-action-desc` gets no `flex` value, so it defaults to `flex: 0 1 auto` and shrinks to max-content. On desktop `.small-action` is 755px (`desktop/topic-post.scss:730-733`), but the desc box is now only as wide as its text, so the delete/edit buttons (`topic-post.scss:313-317`, `float: right`, inside `.small-action-desc`) hug the description text instead of sitting at the row's right edge. `.topic-avatar { float: left }` (`topic-post.scss:267`) is also now inert, since floats do not apply to flex items.
   Fix: add `flex: 1 1 auto; min-width: 0;` to `.small-action-desc` and drop the now-inert `float: left` on `.topic-avatar`.
   (bugs, comments)

Checked: bugs, conventions, history, comments, slop. Deterministic detectors: not run (command not approved).
Skipped: nothing — all 5 files are hand-written SCSS.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
