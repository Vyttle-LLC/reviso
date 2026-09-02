# 2026-09-02 — best-practices lens in the style lane (0.13.0)

Acceptance run for `move-best-practices-to-style`: the `bp-deprecated-api`
pair through `REVISO_TIER=style gold.sh` with `REVISO_CMD_ARGS=--web`,
plus the TP once without the flag. Plugin at the change's working tree,
claude-haiku-4-5-20251001, claude-opus-5, CLI 2.1.258. Live network on the two `--web` legs.

| leg | case | result | cost | wall |
| --- | --- | --- | --- | --- |
| `--web` | `bp-deprecated-api-001` | **1/1 matched**, P2 conf 95, `Source:` cites the python.org datetime page; lens tag `(best practices)` | $0.54 | 68 s |
| `--web` | `bp-deprecated-api-clean-001` | **silent** — and the run's note shows the superseded-idiom bar working: `datetime.UTC` as a shorter alias has no stated consequence, so no finding | $0.80 | 113 s |
| no flag | `bp-deprecated-api-001` | no findings (the naive-datetime crash is a bug, out of the style lane's scope); coverage says `best practices (no --web)`; label out of lane | $0.55 | 96 s |

Same fixture, same label (class/file/line only) as the 0.11.0 audit run
(`2026-09-01-gold-best-practices/`); what moved is the tier. Notable
against that run: the style lane reaches the same finding at ~40% of the
audit's per-case cost, and the flag-off leg stays fully offline.
