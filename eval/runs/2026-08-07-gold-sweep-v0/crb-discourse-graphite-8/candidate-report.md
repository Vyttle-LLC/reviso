## Reviso review — HEAD (detached) vs 4975fc2890 (1 commit, 16 files)

Found 4 issues:

1. [P1][conf 90] `users.delete(id)` bypasses `Group#remove` — stale `user_count` and 500 on non-members — app/controllers/admin/groups_controller.rb:90
   Failure: `has_many :through` `delete` runs `delete_all` on `group_users`, skipping the `counter_cache: "user_count"` callback in app/models/group_user.rb:2 — every removal leaves `groups.user_count` permanently inflated, which drives the admin member count and `totalPages`. Separately, Rails 4.1 resolves a Fixnum via `association.find(id)`, so removing a user who isn't a member raises `ActiveRecord::RecordNotFound` instead of succeeding silently (the behavior commit 50de22801f added a spec for, "succeeds silently when removing non-members", deleted here).
   Fix: `user = User.find_by(id: user_id); group.remove(user) if user` — reuse the existing `Group#remove` (app/models/group.rb:276), which destroys the join rows and keeps the counter cache correct.
   (bugs, history)

2. [P1][conf 85] `add_members` raises 500 when a username is already in the group — app/controllers/admin/groups_controller.rb:73
   Failure: `Group#add` is `self.users.push(user)` (app/models/group.rb:273) with no dedupe, and `group_users` has a UNIQUE index on `(group_id, user_id)` — an admin typing an existing member's name into the new add-members selector gets `ActiveRecord::RecordNotUnique`. The `usernames=` setter this replaces computed `expected - current`, so it was idempotent.
   Fix: skip users already present — `group.add(user) unless group.users.exists?(user.id)` — or guard inside `Group#add`.
   (bugs)

3. [P1][conf 85] `PATCH /admin/groups/:id` still routes here and now silently hides the group — app/controllers/admin/groups_controller.rb:34
   Failure: `update_patch` is gone but `resources :groups` still maps PATCH to `update`. An API client from commit 50de22801f sending `PATCH /admin/groups/5 {changes: {add: "bob"}}` gets HTTP 200 `success_json`, `bob` is not added, and `group.visible = params[:visible] == "true"` evaluates to `false` because `visible` isn't in the payload — the group is silently hidden.
   Fix: if the PATCH membership API is intentionally dropped, return 410/404 for `request.patch?`; and only assign `visible` when `params[:visible].present?` so absent keys don't reset it.
   (history, bugs)

4. [P2][conf 90] `totalPages` off-by-one produces a phantom empty page — app/assets/javascripts/admin/controllers/admin-group.js.es6:13
   Failure: `Math.floor(user_count / limit) + 1` returns 2 for a group with exactly 50 members at `limit: 50`. `showingLast` is false, Next is enabled, `findMembers` requests `offset=50`, and the admin lands on an empty member list reading "2/2".
   Fix: `return Math.ceil(this.get("user_count") / this.get("limit"));` (the `user_count == 0` guard then becomes redundant).
   (bugs)

Checked: bugs, conventions, history, comments, slop. Deterministic detectors did not run — the `detectors/run.sh` call was not approved, so no `deterministic` findings are included.
Skipped: `admin-group-selector.hbs`, `user-selector-autocomplete.raw.hbs` (whitespace only), `admin_base.scss` (styling), and the brace/indentation-only hunks in `admin/groups_controller.rb` and `groups_controller.rb`. No CLAUDE.md/AGENTS.md exists in this repo, so the conventions lens ran against surrounding code style only.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
