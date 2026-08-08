## Todo

- [x] Assemble mock PR (base `3f71fa15c9`, 1 commit, 3 files)
- [x] Read conventions (none: no CLAUDE.md/AGENTS.md/lint configs)
- [~] Deterministic detectors — permission declined, not run
- [x] Review diff, verify candidates, score

---

## Reviso review — HEAD (detached) vs 3f71fa15c9 (1 commit, 3 files)

Found 4 issues:

1. **[P0][conf 100] Duplicate `self.downsize` definition silently shadows the 4-arg version, breaking `Jobs::ResizeEmoji`** — app/models/optimized_image.rb:149
   Failure: `downsize(from, to, max_width, max_height, opts={})` at :145 is immediately redefined at :149 as `downsize(from, to, dimensions, opts={})`. Ruby keeps only the last definition (arity 3..4). `app/jobs/regular/resize_emoji.rb:14` calls `OptimizedImage.downsize(path, path, 100, 100, opts)` with 5 args → `ArgumentError: wrong number of arguments (5 for 3..4)`. That job is enqueued from `app/models/emoji.rb:73`, so every custom-emoji upload now fails at resize time. Line :145 is dead code from the moment it's written.
   Fix: keep one method — `def self.downsize(from, to, dimensions, opts={})` — and update the emoji job to `OptimizedImage.downsize(path, path, "100x100", opts)`. Same for any other `width, height` caller.
   (bugs)

2. **[P1][conf 90] Client-side size check hardcoded to 10MB now governs attachments, not just images** — app/assets/javascripts/discourse/lib/utilities.js:182
   Failure: `validateUploadedFile(file, type, ...)` is called with `type` of `image` *or* `attachment`. Replacing `Discourse.SiteSettings['max_' + type + '_size_kb']` with a flat `10 * 1024` drops `max_attachment_size_kb` from the client entirely — but the new server-side downsizing loop only runs for images (`FileHelper.is_image?`), and `Validators::UploadValidator#maximum_attachment_file_size` still enforces `max_attachment_size_kb` (default 3072). So a 5MB PDF passes the client check and is rejected server-side with a different error, and on a site where an admin raised `max_attachment_size_kb` above 10MB, legitimate attachments are blocked client-side with a message claiming a 10MB limit that isn't the real one. Same hardcode at :246 makes the 413 message report 10MB regardless of the actual limit. `app/assets/javascripts/discourse/controllers/upload-selector.js.es6:17` still reads `max_attachment_size_kb`, so the two paths now disagree.
   Fix: keep the setting lookup for attachments and only override for images, e.g. `var maxSizeKB = type === "image" ? 10 * 1024 : Discourse.SiteSettings.max_attachment_size_kb;`. Better, expose the 10MB ceiling as a site setting instead of duplicating the literal across `utilities.js` (twice) and `uploads_controller.rb:55`.
   (bugs, conventions)

3. **[P1][conf 85] `"80%"` is not a valid geometry for the animated-GIF branch, so large animated GIFs fail all 5 attempts** — app/controllers/uploads_controller.rb:67
   Failure: with `allow_animated_thumbnails` enabled and a `.gif` source, `OptimizedImage.optimize` routes to `downsize_instructions_animated` → `gifsicle #{from} --colors=256 --resize-fit 80% --optimize=3 --output #{to}`. `gifsicle --resize-fit` takes a `WxH` geometry, not a percentage (percentages are `--scale`), so it exits non-zero; `convert_with` returns false. The loop ignores that return value, so it re-runs the same doomed command 5 times, then hands the still-oversized file to `Upload.create_for`, which rejects it. On the non-animated path (`from` has no `.gif` extension — e.g. Rack's multipart tempfile), `convert #{from}[0]` takes frame 0 only and silently strips the animation from the user's upload. This is reachable today via the API URL path, where `FileHelper.download` preserves the extension (`lib/file_helper.rb:13`).
   Fix: break out of the loop when `OptimizedImage.downsize` returns false, and compute a pixel geometry from the source dimensions instead of a percentage so both branches accept it — or skip GIFs in this loop entirely and let the existing thumbnail pipeline handle them.
   (bugs, comments)

4. **[P1][conf 82] SVG uploads are pushed through ImageMagick, contrary to the SVG carve-out every other call site has** — app/controllers/uploads_controller.rb:64
   Failure: `FileHelper.is_image?` matches `.svg` (`lib/file_helper.rb:29`). An SVG larger than `max_image_size_kb` therefore enters the loop and gets rewritten in place by `convert ...[0] -resize 80%\>`, rasterizing/mangling the vector file while `filename` still says `.svg` — and since rasterizing rarely shrinks below the threshold, it runs 5 times. Both existing paths deliberately avoid this: `OptimizedImage.create_for` copies rather than resizes when `extension =~ /\.svg$/i` (app/models/optimized_image.rb:45) and `Upload.create_for` branches to Nokogiri for SVG (app/models/upload.rb:63).
   Fix: add the same guard — `&& filename !~ /\.svg$/i` — to the condition at :64.
   (history, comments)

Checked: bugs, conventions, history, comments, slop.
Skipped: nothing. Deterministic detectors did not run — the `detectors/run.sh` invocation was declined at the permission prompt, so those checks are absent from this report.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
