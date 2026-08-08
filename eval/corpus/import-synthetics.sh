#!/bin/sh
# import-synthetics.sh <fixtures-dir> — import reviso-api's synthetic
# fixtures as diff-only corpus cases (design D6).
#
# Synthetics have no upstream repo to pin. Each imports as:
#   - eval/corpus/synthetic/<id>.json — the reviewable content (all files
#     are status "added" with full-content patches; verified in the task
#     1.1/1.6 audit), authored in reviso-api (Vyttle's own, committable)
#   - eval/corpus/labels/<id>.json — gold labels, same schema/mapping as
#     the CRB import, origin "synthetic"
#   - a public.jsonl entry with synthetic: true — gold mode materializes
#     the case into a throwaway git repo; parity tooling refuses it
# Idempotent: ids already in public.jsonl are left untouched.
set -eu
FIXTURES="${1:?usage: import-synthetics.sh <fixtures-dir>}"
HERE=$(cd "$(dirname "$0")" && pwd)
CORPUS="$HERE/public.jsonl"
mkdir -p "$HERE/labels" "$HERE/synthetic"
[ -f "$CORPUS" ] || : > "$CORPUS"

imported=0; existing=0
for f in "$FIXTURES"/*.json; do
  [ "$(jq -r '.source // ""' "$f")" = "synthetic" ] || continue
  id=$(jq -r '.id' "$f")
  if grep -q "\"id\": \"$id\"" "$CORPUS"; then
    existing=$((existing + 1)); continue
  fi
  if jq -e '[.files[].status] | any(. != "added")' "$f" >/dev/null; then
    echo "import-synthetics.sh: SKIPPED $id — non-added file status; materialization assumes full-content patches" >&2
    exit 1
  fi

  jq '{id, language: (.language // null), difficulty: (.difficulty // null),
       pr: {title: .pr.title, description: .pr.description},
       expected_clean: (.expected_clean // false),
       files: [.files[] | {filename, status, patch}]}' "$f" \
    > "$HERE/synthetic/$id.json"

  jq --arg date "$(date -u +%Y-%m-%d)" '{
    case: .id,
    origin: "synthetic",
    imported: $date,
    expected_clean: (.expected_clean // false),
    findings: [ (.gold_issues // [])[] | {
      file: (if .file == "*" or .file == null then null else .file end),
      line: (.line // 0),
      title: ((.description // "")[0:120]),
      severity: (.severity // null),
      category: ({bug: "correctness", security: "security",
                  "error-handling": "robustness",
                  performance: "efficiency"}[.category] // .category),
      crb_category: (.category // null),
      description: (.description // "")
    } ]
  }' "$f" > "$HERE/labels/$id.json"

  lang=$(jq -r '.language // ""' "$f")
  jq -n --arg id "$id" --arg lang "$lang" \
    '{id: $id, synthetic: true, fixture: ("synthetic/" + $id + ".json"),
      language: $lang, active_parity: false,
      labels: ("labels/" + $id + ".json"),
      notes: "Synthetic gold-mode-only case (authored in reviso-api). Parity tooling refuses synthetics."}' \
    | jq -c . >> "$CORPUS"
  imported=$((imported + 1))
done
echo "import-synthetics.sh: imported $imported, already present $existing" >&2
