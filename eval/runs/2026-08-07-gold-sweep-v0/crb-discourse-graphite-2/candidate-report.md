## Reviso review — HEAD (detached) vs 56abd247e1 (1 commit, 18 files)

Found 2 issues:

1. **[P1][conf 88] `unsubscribe` writes `topic_users` directly instead of going through `TopicUser.change`** — `app/controllers/topics_controller.rb:105`
   Failure: two concrete failures from the same bypass.
   (a) `TopicUser.find_by` returns `nil` for a user with no row for that topic (link forwarded, or opened while signed into a different account, or any logged-in user hitting the guessable URL) → `nil.notification_level` raises `NoMethodError`, 500 on line 107. `TopicUser.change` creates the row when missing; this path doesn't.
   (b) The manual `notification_level=` + `save!` never sets `notifications_reason_id` / `notifications_changed_at`, which `TopicUser.change` sets to `:user_changed` (`app/models/topic_user.rb:158-161`). A row created by `notification_email` (`app/mailers/user_notifications.rb:312`) has `notifications_reason_id = NULL`, so after the user unsubscribes to `muted`, the next read of that topic hits `TopicUser.update_last_read`'s SQL (`app/models/topic_user.rb:155-165`: `case when tu.notifications_reason_id is null and total_msecs_viewed > threshold then :tracking`) and silently re-subscribes them at `tracking`. Same for `TopicUser.auto_track`, which only fires when the reason is NULL. Unsubscribing via the existing notifications dropdown (`topics#set_notifications` → `TopicUser.change`) sticks; unsubscribing from the email does not.
   Also missing: the `MessageBus.publish("/topic/#{id}", notification_level_change: ...)` that `TopicUser.change` emits, so other open tabs keep showing the old level.
   Fix: replace lines 105-113 with a read of the current level plus a single `TopicUser.change` call, e.g.
   ```ruby
   tu = TopicUser.find_by(user_id: current_user.id, topic_id: params[:topic_id])
   levels = TopicUser.notification_levels
   new_level = (tu && tu.notification_level > levels[:regular]) ? levels[:regular] : levels[:muted]
   TopicUser.change(current_user.id, params[:topic_id].to_i, notification_level: new_level)
   ```
   (bugs; history — the reason-id invariant is what `TopicUser.change`'s comment and `auto_track`'s `notifications_reason_id: nil` guard have enforced since the auto-track feature landed)

2. **[P2][conf 80] Unsubscribe page claims notifications stop, but one click only drops watching → regular** — `app/assets/javascripts/discourse/templates/topic/unsubscribe.hbs:3`
   Failure: the email says "To stop receiving notifications about this particular topic, click here" and the landing page unconditionally renders `topic.unsubscribe.stop_notifications` — "You will stop receiving notifications for **{title}**." For a user at `watching`, the server sets `regular` (`topics_controller.rb:107-108`), and `PostAlerter` only suppresses notifications at `muted` (`app/services/post_alerter.rb:105`), so they keep getting emails for replies and mentions. The user believes they are unsubscribed and is not.
   Fix: have the server report the resulting level (it is already in the serialized topic details) and pick the string from it — a "you will now only be notified when someone replies to you" variant for `regular`, the existing string only for `muted`.
   (bugs — claim not matched by enforcement)

Checked: bugs, conventions, history, comments, slop.
Skipped: `config/locales/*.yml` and the pure-reformatting hunks in `topic_user.rb`, `message_builder.rb`, `topic-from-params.js.es6`, `notification.html.erb`, `topic.scss` (no behavior change). Deterministic detector suite did not run — the `detectors/run.sh` call was not approved, so those checks are absent from this pass.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
