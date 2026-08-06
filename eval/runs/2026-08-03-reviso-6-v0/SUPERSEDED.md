# Superseded baseline protocol

These artifacts predate the `re-aim-parity-eval` change (2026-08-06) and are
**not comparable** with runs made after it. Their baseline invoked `/review`
with no pinned level (ambient effort decided what ran), the runner's
allowlist did not permit subagent fan-out, and no CLI version or resolved
level was recorded — so what pipeline the baseline actually measured cannot
be reconstructed. Upstream `/review` was later confirmed to be the
CLI-embedded, effort-scaled skill, making all three of those omissions
identity-defining (see eval/README.md and eval/reference/).

Kept as history of the v0/v0.3 candidate iterations; do not cite their
parity or cost numbers against re-aimed runs.
