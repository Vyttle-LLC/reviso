## Reviso review — HEAD (detached) vs 62db063e (1 commit, 27 files)

Found 5 issues:

1. **[P0][conf 95] Stray `if` in `<%- end if %>` makes the embed template fail to compile** — `app/views/embed/best.html.erb:6`
   Failure: ERB emits `end if` followed by the next output statement, so `end` closes the `posts.present?` conditional and the bare `if` opens a new one that is never closed. The template raises `SyntaxError: unexpected end-of-input, expecting keyword_end` at compile time, so `GET /embed/best` 500s for every embed URL that already has a topic — i.e. the main path of the feature. No spec catches it: `render_views` is never enabled anywhere in `spec/`, so `embed_controller_spec.rb` exercises the action without compiling the view.
   Fix: `<%- end %>` on line 6.
   (bugs)

2. **[P1][conf 85] `poll_feed` crashes on plain RSS 2.0 feeds and the job never retries** — `app/jobs/scheduled/poll_feed.rb:35`
   Failure: `i.content` is only populated for Atom `<content>` / `content:encoded`. A standard RSS 2.0 item carries its body in `<description>`, so `i.content` is `nil` and `nil.scrub` raises `NoMethodError`. The raise happens inside `rss.items.each` with no per-item rescue, so the first such item aborts the whole poll — and `sidekiq_options retry: false` means it is never retried. The setting text (`feed_polling_url`: "URL of RSS/ATOM feed to import") promises RSS support the code doesn't deliver.
   Fix: `content = i.content || i.description; next if content.blank?` before unescaping, and wrap the per-item body in a `begin/rescue` + log so one bad item doesn't kill the batch.
   (bugs)

3. **[P2][conf 85] `absolutize_urls` corrupts protocol-relative URLs and skips path-relative ones** — `app/models/topic_embed.rb:64`
   Failure: `href.sub(/^\/+/, '')` strips *all* leading slashes, so `//cdn.example.com/img.png` (very common in syndicated HTML) becomes `http://blog.example.com/cdn.example.com/img.png` — a broken link where the original was fine. Conversely `images/wat.jpg` fails `start_with?('/')` and is left relative, so it still resolves against the forum host. Both contradict the comment on line 55, "Convert any relative URLs to absolute". Same defect at line 70 for `img src`.
   Fix: use `URI.join(url, href).to_s` guarded by `rescue URI::Error` instead of the manual prefix/`sub` dance — it handles absolute, protocol-relative and path-relative inputs correctly in one call.
   (comments)

4. **[P2][conf 82] Disqus importer silently drops thread dates and categories, and one dead link aborts the run** — `lib/tasks/disqus.thor:148`
   Failure: the replaced `PostCreator.new(..., created_at: Date.parse(t[:created_at]), category: category_id)` passed the original thread date; `TopicEmbed.import_remote` does not, so every imported topic is stamped "now" while its replies keep their historical `created_at` (line 163) — replies dated years before the topic they answer. The `--category` option was deleted with no replacement. Additionally `import_remote` does `open(url).read` per thread with no rescue, so a single 404/timeout on an old permalink raises out of the `each` and kills a partially-completed import. Nothing in the commit message states these as intended.
   Fix: pass `created_at`/`category` through `import_remote` → `import` → `PostCreator`, and wrap the per-thread call in `rescue => e; puts "skipping #{t[:link]}: #{e}"; next`.
   (history)

5. **[P2][conf 90] Unused `require_dependency 'email/sender'` in the retrieve-topic job** — `app/jobs/regular/retrieve_topic.rb:1`
   Failure: the job touches `User`, `TopicRetriever` and nothing mail-related; the require is copy-paste from another job and loads the mail stack on every worker boot for no reason.
   Fix: delete line 1, keep `require_dependency 'topic_retriever'`.
   (slop)

Checked: bugs, conventions, history, comments, slop.
Skipped: `Gemfile_rails4.lock` (lockfile); `app/assets/stylesheets/embed.css.scss` (pure styling); the whitespace-only edits to `db/migrate/20131210181901_migrate_word_counts.rb` and the `force: true` restoration in `db/migrate/20131223171005_create_top_topics.rb` (both re-apply state from the reverted `e3e4c62`, so deliberate). The deterministic detector suite did not run — the `sh .../detectors/run.sh` call was denied, so no `deterministic` findings are included.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
