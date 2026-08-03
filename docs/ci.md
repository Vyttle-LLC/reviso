# Running Reviso in CI

> **Stub.** Content lands with the plugin release —
> TODO(plugin): write this properly.

Running Reviso in CI is allowed, and we'd rather document it than have people
guess.

One thing to get right before you do: **use an API key, not a personal
subscription.** Claude subscriptions are licensed for interactive personal use;
automation belongs on an API key. If you want a hosted, supported version that
runs on your PRs without you wiring any of this up, that's Reviso Cloud.

This page will cover:

- A minimal GitHub Actions workflow
- Which command to run in a non-interactive context, and how to read its exit code
- Keeping the review report-only in CI
- Cost expectations per PR
