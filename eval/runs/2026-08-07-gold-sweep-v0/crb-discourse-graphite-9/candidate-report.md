Detectors could not run — the `run.sh` invocation was not approved, so no deterministic findings are included below. Everything here is from the manual pass.

```text
## Reviso review — HEAD vs 728845d008 (1 commit, 7 files)

Found 3 issues:

1. [P1][conf 88] Fallbacks are inert outside the web request path — app/controllers/application_controller.rb:159
   Failure: `I18n.fallbacks.ensure_loaded!` is the only thing that loads the
   fallback locales, and it is called only from `ApplicationController#set_locale`.
   `I18n.translate` (lib/freedom_patches/translate_accelerator.rb:68) still loads
   only `config.locale`, and `I18n::Backend::Fallbacks#translate` calls
   `super(fallback, ...)` straight into the Simple backend — no load hook. So in
   the Sidekiq process, where `app/jobs/base.rb:151` sets
   `I18n.locale = SiteSetting.default_locale` and never calls `ensure_loaded!`,
   `:en` is never loaded. On a site with `default_locale = de`, every digest /
   notification email key that exists only in `en` still resolves to
   MissingTranslation. Same for `I18n.with_locale(user.effective_locale)` in
   app/services/post_alerter.rb:138, `lib/post_destroyer.rb:102`, and
   `lib/tasks/db.rake:3`. Emails are the main consumer of server-side fallbacks,
   and they are exactly where the feature does not work.
   Fix: put the load where the lookup happens instead of at each call site — in
   translate_accelerator.rb:68, replace
   `load_locale(config.locale) unless @loaded_locales.include?(config.locale)`
   with `I18n.fallbacks.ensure_loaded!` (or loop `I18n.fallbacks[config.locale]`
   calling `ensure_loaded!` on each), then drop the controller call.
   (bugs)

2. [P1][conf 84] Translation LRU cache key doesn't include the site's default_locale — config/initializers/i18n.rb:17
   Failure: the cache key at lib/freedom_patches/translate_accelerator.rb:72 is
   `key + config.locale + backend.object_id`. `I18n::Config#backend` is a class
   variable, so `object_id` is identical for every site in a multisite process.
   Before this change a translation was a pure function of (key, locale) — the
   old `config.i18n.fallbacks = true` fell back to the process-global
   `I18n.default_locale`. Now the result also depends on
   `SiteSetting.default_locale`, which is per-site and mutable. Two sites in one
   unicorn process with `default_locale` `en` and `fr`, both serving a user with
   `locale = de`: whichever site touches a de-missing key first poisons the entry,
   and the other site gets the wrong language. Single-site variant: an admin
   changing `default_locale` leaves stale fallbacks cached until restart —
   nothing calls `I18n.reload!` on that setting change.
   Fix: fold the site into the key, e.g.
   `k = "#{key}#{config.locale}#{RailsMultisite::ConnectionManagement.current_db}#{config.backend.object_id}"`,
   or clear `@cache` from a `default_locale` site-setting change hook.
   (bugs)

3. [P2][conf 80] Uncached fallback list runs a SiteSetting lookup on every translate — config/initializers/i18n.rb:13
   Failure: `FallbackLocaleList#[]` subclasses Hash but never uses its storage —
   it recomputes `[locale, SiteSetting.default_locale.to_sym, :en].uniq.compact`
   on every call. `I18n::Backend::Fallbacks#translate` calls `I18n.fallbacks[locale]`
   on every backend lookup, not just on misses, and every interpolated
   `I18n.t(key, count: n)` bypasses the LRU cache (`args.length > 0` at
   translate_accelerator.rb:69). The stock `I18n::Locale::Fallbacks` memoizes
   (`self[locale] ||= compute(locale)`) precisely to avoid this; this file's header
   comment states its purpose is to make translation fast.
   Fix: memoize per (locale, default_locale) rather than per locale —
   `def [](locale); super || compute_and_store(locale); end` keyed on
   `"#{locale}-#{SiteSetting.default_locale}"`, so a default_locale change
   invalidates naturally. Note this interacts with finding 2: a naive
   `self[locale] ||=` would make the cross-site leak worse.
   (slop, comments)

Checked: bugs, conventions, history, comments, slop.
Skipped: deterministic detectors (command not approved); no CLAUDE.md/AGENTS.md in repo.
```

Two things I checked and did not flag: the `# order: after 02-freedom_patches.rb` comment holds (`i18n.rb` sorts after all numbered initializers), and removing `config.i18n.fallbacks = true` is safe on Rails 4.1.10 — `validate_fallbacks` rejects the default empty `OrderedOptions`, so the railtie's `after_initialize` won't clobber `I18n.fallbacks`. The commit message's claim that `I18n.default_locale` was `SiteSetting.default_locale` is not accurate (nothing assigns `I18n.default_locale`, so it was `:en`), but the conclusion — that the old config was near-useless — still holds since `:en` was never loaded either.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
