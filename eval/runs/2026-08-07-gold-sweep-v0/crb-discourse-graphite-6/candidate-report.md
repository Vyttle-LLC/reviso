## Reviso review — HEAD (detached) vs 7a5fbae060 (1 commit, 5 files)

Note: the deterministic detector suite was not approved to run, so this pass is LLM-only — no `deterministic` findings.

Found 3 issues:

1. **[P1][conf 95] `website_name` bypasses the `untrusted_attributes` gate that hides `website` from anonymous TL0 profiles — app/serializers/user_serializer.rb:43**
   Failure: `untrusted_attributes` (line 105–111) lists `:website` but not `:website_name`, so for a TL0 user viewed by an anonymous visitor `include_website?` returns false while `website_name` is still serialized. `user.hbs:66` gates the whole block on `{{#if model.website_name}}`, so a spammer's `spam-site.com/promo` now renders as visible text (with an empty `href`) on the profile — and the field is exposed in the JSON API — exactly what the TL0 restriction exists to prevent. The existing spec's `untrusted_attributes` list (spec/serializers/user_serializer_spec.rb:11) was not updated either, so nothing catches it.
   Fix: add `:website_name` to the `untrusted_attributes` call at line 105 and to the spec list at line 11.
   (bugs)

2. **[P1][conf 90] `include_website_name` is missing the trailing `?`, so it never runs — app/serializers/user_serializer.rb:153**
   Failure: ActiveModel::Serializers looks up `include_<attr>?`; this serializer's own `staff_attributes`/`private_attributes`/`untrusted_attributes` helpers all define `"include_#{attr}?"` (lines 9, 18, 27), and every other conditional in the file uses `?` (`include_email?`, `include_card_image_badge_id?`, …). As written the method is dead code: `website_name` is emitted unconditionally, so every user payload carries `"website_name": null` and `website_name` runs `URI()` + `Discourse.current_hostname` for users with no website.
   Fix: rename to `def include_website_name?`.
   (conventions)

3. **[P2][conf 85] Website in the profile header no longer updates after saving preferences — app/assets/javascripts/discourse/templates/user/user.hbs:66**
   Failure: `preferences` is nested inside the `user` resource (routes/app-route-map.js.es6:74), so `user.hbs` renders the header above the preferences form on the same `model`. The removed `websiteName` computed property was `.property('model.website')` and recomputed on save; `User#save` only copies `bio_excerpt` back from the response (models/user.js.es6:210). So a user who sets a website for the first time and saves sees `model.website` update but `model.website_name` stay undefined — the globe icon and link never appear until a full page reload.
   Fix: in `save()`'s `.then`, also `self.set('website_name', data.user.website_name)` alongside the existing `bio_excerpt` copy (the PUT response is a `UserSerializer` dump).
   (bugs; history — the property removed in controllers/user.js.es6:17 was the reactive link)

Checked: bugs, conventions, history, comments, slop. Detectors not run (permission not granted).
Skipped: nothing.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
