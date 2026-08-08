## Reviso review — HEAD (detached, 0 commits) vs df49cca (1 file)

Found 1 issue:

1. [P0][conf 95] Path traversal — user-controlled path joined to UPLOAD_DIR with no containment check — src/routes/downloads.py:22
   Failure: The route uses the `<path:filename>` converter, so `filename` may contain `/` and `..` segments. `GET /api/files/..%2f..%2f..%2fetc/passwd` (or `../../config/settings.py`, `../../.env`) decodes to `../../../etc/passwd`; `os.path.join(UPLOAD_DIR, filename)` resolves outside the uploads directory, `os.path.isfile` passes, and `send_file` streams the file with no sanity check of its own (unlike `send_from_directory`, `send_file` performs no directory containment check). Any authenticated user gets arbitrary file read at the web process's privileges — secrets, source, keys. The docstring at :16-17 claims the name is "resolved against the uploads directory", but nothing enforces that.
   Fix: Let Werkzeug do the containment check:
   ```python
   from flask import send_from_directory
   ...
   try:
       return send_from_directory(UPLOAD_DIR, filename, mimetype=mime_type, as_attachment=True)
   except NotFound:
       abort(404)
   ```
   `send_from_directory` rejects absolute paths, `..` escapes, and (by default) symlinks pointing outside the directory. If you keep the manual join, verify containment before any stat or send:
   ```python
   base = os.path.realpath(UPLOAD_DIR)
   file_path = os.path.realpath(os.path.join(base, filename))
   if os.path.commonpath([base, file_path]) != base or not os.path.isfile(file_path):
       abort(404)
   ```
   Note that `mimetypes.guess_type` must then run on the validated path. Also consider whether subdirectories should be reachable at all — `list_files` only ever exposes top-level entries, so `<string:filename>` would match the advertised surface more closely than `<path:filename>`.
   (bugs)

Checked: bugs, conventions, history, comments, slop.
Skipped: nothing. Note: the deterministic detector suite (`detectors/run.sh`) could not run — it lives outside this session's allowed working directories and the call was blocked, so no `deterministic` findings are included. No CLAUDE.md/AGENTS.md or lint config exists in this repo, so the conventions lens had nothing repo-specific to check against.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
