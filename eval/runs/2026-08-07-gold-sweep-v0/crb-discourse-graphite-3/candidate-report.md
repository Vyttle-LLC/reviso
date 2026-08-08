## Reviso review — HEAD (detached) vs e25638dab0 (1 commit, 10 files)

Note: the deterministic detector suite (`detectors/run.sh`) was not approved to run, so no `deterministic` findings are included below.

Found 1 issue:

1. **[P1][conf 85] Blocked-email match stats are rolled back by the enclosing save transaction** — `lib/validators/email_validator.rb:13` (anchor also `app/models/blocked_email.rb:16`)
   Failure: `BlockedEmail.should_block?` writes `match_count`/`last_match_at` from inside a validator. On Rails 3.2 (Gemfile.lock: 3.2.12), `ActiveRecord::Transactions` is included *after* `Validations`, so `Transactions#save`/`save!` is outermost and validations run inside its transaction, which is rolled back whenever validation fails. Concretely: `InviteRedeemer#redeem` → `User.create_for_email("blocked@spam.org")` (`app/models/user.rb:103`, `user.save!`) → validator bumps the counter → `EmailValidator` adds the `blocked` error → `save!` raises `RecordInvalid` → the whole transaction, including the counter update, is rolled back. `match_count` stays 0 and `last_match_at` stays `nil` for exactly the events they exist to record — contradicting the commit message ("Track stats of how many times each email address is blocked") and the comment at `spec/models/blocked_email_spec.rb:13` ("we can see whether those emails have ever been blocked by looking at `last_match_at`"). The signup path only records anything by accident: `UsersController#create:168` calls `user.valid?` outside any transaction before `user.save`, so that one call sticks while the identical one during `save` is discarded. Neither spec catches this — `email_validator_spec.rb` stubs `should_block?` and `blocked_email_spec.rb` calls it directly, so nothing exercises the stat through a real `User#save`.
   Fix: split the query from the write. Make `should_block?` a pure predicate, and record the hit outside the failing save — e.g.

   ```ruby
   def self.block?(email)
     where(email: email).where(action_type: actions[:block]).exists?
   end

   def self.record_match!(email)
     where(email: email).update_all("match_count = match_count + 1, last_match_at = now()")
   end
   ```

   with `record_match!` invoked from the error branch of `UsersController#create` (and any other blocked path), not from `validate_each`. Add a spec that asserts the counter after a real `User#save` on a blocked email — that is the case currently uncovered.
   (bugs; enforcement doesn't match its claim)

Checked: bugs, conventions, history, comments, slop.
Skipped: nothing (detectors not run — permission declined).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
