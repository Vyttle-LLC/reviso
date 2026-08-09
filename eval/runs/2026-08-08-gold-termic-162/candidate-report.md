## Reviso review — HEAD vs 727a3b2 (4 commits, 15 files)

Found 3 issues:

1. **[P2][conf 90] The "live same-project duplicate" rule is hand-inlined in 7 places** — src-tauri/src/lib.rs:2776
   Also at `src-tauri/src/lib.rs:2978` (task_import_worktree), `:3900` (task_rename), `:5053` (task_restore_sync), `:7236` (`unique_task_name`'s `taken`), `src-tauri/src/cli_server.rs:2346` (handle_rename), `src-tauri/src/cli_server.rs:967` (handle_new, pre-existing). Six of the seven are new in this branch. The message `"a task named \"{n}\" already exists in this project"` is separately re-spelled at `lib.rs:2778`, `:2980`, `:3902`.
   Failure: this is the policy of the whole change ("what counts as a name collision"). A future edit, exempting main-checkout tasks, switching to Unicode case folding, or counting archived tasks, lands in one or two copies and the other five silently disagree, so `rename` refuses a name that `task_open_repo` happily mints.
   Fix: one helper next to `unique_task_name` in the helpers section of `src-tauri/src/lib.rs`, returning the offender so `cli_server` can still name it:
   ```rust
   /// The LIVE task in `project_id` already holding `name`, if any.
   /// `except` is the task allowed to keep it (itself, on rename/restore).
   pub(crate) fn live_name_holder<'a>(
       tasks: &'a [Task], project_id: &str, name: &str, except: Option<&str>,
   ) -> Option<&'a Task> {
       tasks.iter().find(|t| {
           Some(t.id.as_str()) != except
               && !t.archived
               && t.project_id == project_id
               && t.name.eq_ignore_ascii_case(name)
       })
   }
   ```
   `task_rename` then reads `if live_name_holder(&list, &list[idx].project_id, new_name, Some(&id)).is_some() { return Err(duplicate_name_error(new_name)); }`; `cli_server.rs` calls `crate::live_name_holder(&tasks, &t.project_id, new_name, Some(&t.id))` and keeps its `qualified()` message.
   (slop/duplication)

2. **[P2][conf 88] "worktree creates are de-facto name-guarded by their directory" does not hold, so the GUI New Task dialog still mints twins** — src-tauri/src/lib.rs:2661
   Failure: `task_create_sync` (src-tauri/src/lib.rs:3059) has no name check at all; its only guard is `wt_path = tasks_path/slugify(name)` already being a registered worktree (`:3095`). A repo-root task has no directory under `tasks_path`, and an imported-worktree task's directory lives elsewhere. So: quick Terminal on `web` mints a repo-root task named `main`, then New Task → name `main` finds `tasks/web/main` free and creates the second live `main`. `resolve_by_name` now answers `task "main" exists in more than one project: web/main, web/main. Disambiguate with --project or project/name` — and neither escape works, which is exactly the state the branch exists to prevent. The dialog has no client-side guard either (`NewTaskDialog.tsx:915` only checks non-empty), unlike the CLI's `new` path (`cliRpc.ts:161`).
   Fix: apply the finding-1 helper in `task_create_sync` right after the empty-slug guard (and in `task_create_multi_sync`, same shape), returning the shared duplicate message — or drop the completeness claim from the `task_open_repo` doc comment and say worktree creates are knowingly unguarded.
   (bugs; enforcement vs. claim)

3. **[P2][conf 85] `machine_help_covers_the_surface` was not extended to `rename`** — termic-cli/src/lib.rs:2156
   Failure: the test's expected-verb list still ends `"quit", "project add", "project list", "project remove", "help"`. `machine_help()` is clap-derived, so `rename` is in the output today, but the guard whose job is "the machine surface covers every verb" will stay green if a later refactor drops `rename` from the subcommand tree or from `machine_help`, which is the one thing agents parse to discover it.
   Fix: add `"rename"` to the array; optionally assert `by_name("rename")["exit_codes"]["1"]` so the after_help's exit-code contract is pinned too.
   (conventions/test-coverage)

Checked: bugs, conventions, history, comments, slop, deterministic (detector suite returned nothing).
Skipped: nothing.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
