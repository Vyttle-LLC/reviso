#!/bin/sh
# import-crb.sh <fixtures-dir> — convert reviso-api's CRB fixtures into
# public-tier corpus entries plus gold labels files.
#
# For each crb-*.json fixture: read identity (the PR URL in source_id) and
# gold_issues, resolve current base/head SHAs via `gh`, and emit
#   - an entry line appended to eval/corpus/public.jsonl
#   - a labels file at eval/corpus/labels/<id>.json
# A fixture whose PR or SHAs cannot be resolved is SKIPPED LOUDLY and
# listed in the final report; no entry is ever emitted with guessed SHAs.
# No upstream diff content is copied — entries stay pointers (design D1).
#
# Idempotent: fixtures whose id already appears in public.jsonl are
# reported as existing and left untouched.
#
# Category mapping (task 1.1 audit; original kept as crb_category):
#   bug → correctness, security → security, error-handling → robustness,
#   performance → efficiency. Unknown categories pass through unchanged —
#   the judge tiers unknown slugs as correctness (fail-loud).
#
# Synthetic fixtures (bug-*/clean-*/security-*) are handled by
# import-synthetics (task 1.6), not this script.
set -eu
FIXTURES="${1:?usage: import-crb.sh <fixtures-dir>}"
HERE=$(cd "$(dirname "$0")" && pwd)
CORPUS="$HERE/public.jsonl"
LABELS_DIR="$HERE/labels"
mkdir -p "$LABELS_DIR"
[ -f "$CORPUS" ] || : > "$CORPUS"

imported=0; existing=0; skipped=""
for f in "$FIXTURES"/crb-*.json; do
  [ -f "$f" ] || { echo "import-crb.sh: no crb-*.json fixtures in $FIXTURES" >&2; exit 1; }
  id=$(jq -r '.id' "$f")
  if grep -q "\"id\": \"$id\"" "$CORPUS"; then
    existing=$((existing + 1)); continue
  fi

  url=$(jq -r '.source_id // ""' "$f")
  case "$url" in
    https://github.com/*/pull/*) ;;
    *) skipped="$skipped\n  $id: source_id is not a PR URL ($url)"; continue ;;
  esac
  repo=$(printf '%s' "$url" | sed -E 's|https://github.com/([^/]+/[^/]+)/pull/.*|\1|')
  pr=$(printf '%s' "$url" | sed -E 's|.*/pull/([0-9]+).*|\1|')

  shas=$(gh pr view "$pr" --repo "$repo" --json baseRefOid,headRefOid \
           -q '.baseRefOid + " " + .headRefOid' 2>/dev/null) || shas=""
  base=${shas%% *}; head=${shas##* }
  if [ -z "$base" ] || [ -z "$head" ] || [ "$base" = "$head" ]; then
    skipped="$skipped\n  $id: could not resolve SHAs for $repo#$pr"; continue
  fi

  lang=$(jq -r '.language // ""' "$f")
  jq -n --arg id "$id" --arg repo "$repo" --argjson pr "$pr" \
    --arg base "$base" --arg head "$head" --arg lang "$lang" \
    --arg notes "Imported from code-review-benchmark (MIT; see labels/LICENSE-code-review-benchmark). Gold labels: labels/$id.json." \
    '{id: $id, repo: $repo, pr: $pr, base_sha: $base, head_sha: $head,
      clone_url: ("https://github.com/" + $repo + ".git"),
      language: $lang, active_parity: false,
      labels: ("labels/" + $id + ".json"), notes: $notes}' \
    | jq -c . >> "$CORPUS"

  jq --arg date "$(date -u +%Y-%m-%d)" '{
    case: .id,
    origin: "code-review-bench",
    imported: $date,
    source_pr: .source_id,
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
  }' "$f" > "$LABELS_DIR/$id.json"
  imported=$((imported + 1))
done

echo "import-crb.sh: imported $imported, already present $existing" >&2
if [ -n "$skipped" ]; then
  printf 'import-crb.sh: SKIPPED (no entry emitted):%b\n' "$skipped" >&2
  exit 1
fi
