## Reviso review — HEAD vs 913c3d6f (1 commit, 35 files)

Found 6 issues:

1. **[P0][conf 95] Migration aborts on every site that never set `embed_category`** — `db/migrate/20150818190757_create_embeddable_hosts.rb:11`
   Failure: `execute(...)[0]['id']` indexes row 0 of the result unconditionally. `embed_category` defaults to `''` and is only persisted in `site_settings` when overridden, so the `INNER JOIN ... ON s.value = c.name` returns zero rows for almost every install (and for a fresh DB, where `site_settings` is seeded after migrations). `PG::Result#[]` raises `IndexError` out of range, the migration aborts, and the upgrade fails. Line 15 has the same unguarded `[0]['value']`. The same file already guards the third query with `if embeddable_hosts && embeddable_hosts.cmd_tuples > 0` — the first two need the same treatment.
   Fix: `rows = execute(...); category_id = rows.cmd_tuples > 0 ? rows[0]['id'].to_i : 0` for both lookups, defaulting to `0` / then to the uncategorized fallback.
   (bugs)

2. **[P1][conf 90] Migration copies host values verbatim, so migrated hosts never match the new lookup** — `db/migrate/20150818190757_create_embeddable_hosts.rb:25`
   Failure: the old `embeddable_hosts` setting explicitly accepted schemes and paths — the specs this PR deletes assert `SiteSetting.embeddable_hosts = 'http://eviltrout.com'` and `"...\nhttp://discourse.org\nhttps://example.com/1234"`, and `embed_controller_spec.rb:68` still fabricates `host: 'http://discourse.org'` relying on the model's `before_validation` to strip it. The migration inserts raw SQL, bypassing that callback, so rows land as `http://discourse.org`. `EmbeddableHost.record_for_host` compares against `URI(referer).host` (`discourse.org`), so no row matches and embedding silently stops working after upgrade. A value containing a `'` also breaks the interpolated INSERT and aborts the migration.
   Fix: normalize in Ruby before inserting — `h = h.sub(/\Ahttps?:\/\//, '').sub(/\/.*\z/, '').strip` — and use `quote(h)` instead of `'#{h}'`.
   (bugs; history)

3. **[P1][conf 85] `lower(host) = ?` never downcases the parameter** — `app/models/embeddable_host.rb:17`
   Failure: `URI#host` preserves the case in the Referer header. For a page at `http://EvilTrout.com/post`, the query becomes `lower(host) = 'EvilTrout.com'`, which can never match — `lower()` always yields lowercase. `host_allowed?` returns false and `EmbedController#ensure_embeddable` raises `invalid referer host`, so embedding breaks for any host authored with mixed case, even though the `lower()` call shows case-insensitive matching was intended. `TopicRetriever#invalid_host?` hits the same path.
   Fix: `where("lower(host) = ?", host.downcase).first`.
   (bugs)

4. **[P2][conf 88] Fabricator file contents are swapped** — `spec/fabricators/category_fabricator.rb:1`
   Failure: `category_fabricator.rb` now contains only `Fabricator(:embeddable_host)`, and the new `embeddable_host_fabricator.rb` contains all four category fabricators (`:category`, `:diff_category`, `:happy_category`, `:private_category`). Tests still pass because Fabrication loads the whole directory, but anyone editing a category fabricator will open the wrong file, and a future rename/delete of `embeddable_host_fabricator.rb` silently takes the category fabricators with it.
   Fix: swap the two files' contents back.
   (conventions)

5. **[P2][conf 85] Admin host endpoints 500 on missing params or unknown id instead of erroring cleanly** — `app/models/embeddable_host.rb:6`
   Failure: `before_validation` calls `self.host.sub!` with no nil guard, so `POST /admin/embeddable_hosts` without a `host` param raises `NoMethodError` on `nil` and returns a 500 rather than the `render_json_error` path the controller sets up — `validates_format_of` never gets a chance to report the blank. Separately, `embeddable_hosts_controller.rb:16` calls `host.destroy` on the result of `where(id: ...).first` with no presence check, so `DELETE` with a stale id 500s; `update` (line 10) has the same hole. The sibling `Admin::UserFieldsController#destroy` guards this exact case with `field.destroy if field.present?`.
   Fix: `self.host = host.to_s.sub(...).sub(...)` in the callback (or `return if host.blank?`), and guard the two lookups the way `UserFieldsController` does.
   (bugs; conventions)

6. **[P2][conf 88] `PUT /admin/customize/embedding` and the `saveChanges` action are no-ops** — `app/controllers/admin/embedding_controller.rb:9`
   Failure: `#update` re-renders `@embedding` without writing anything, and `admin-embedding.js.es6:5` calls `this.get('embedding').update({})` against it. Nothing in `embedding.hbs` wires up `saveChanges`, so today it is dead code, but the route reads as a working save endpoint — the next person to add a Save button will get a green success response and no persistence. Hosts are the only mutable state here and they already save individually via `Admin::EmbeddableHostsController`.
   Fix: drop `saveChanges`, `EmbeddingController#update`, and the `put "customize/embedding"` route (`config/routes.rb:139`) until there is state to save.
   (bugs; slop)

Checked: bugs, conventions, history, comments, slop.
Skipped: nothing. Note: the deterministic detector suite (`detectors/run.sh`) was not approved to run, so no `deterministic`-tagged findings are included; the six above are all from manual review.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
