#!/bin/sh
# gold.sh <case-id> <outdir> — run the candidate against a gold-labeled
# corpus case and judge its findings against the labels. No upstream
# review is invoked at any point (gold-eval spec): the only model costs
# are the candidate run and the matcher.
#
# Real cases: blobless clone into the cache (eval/.cache/clones/), fetch
# the pinned SHAs, throwaway worktree, candidate leg via candidate.sh.
# Synthetic cases: materialize the fixture into a throwaway git repo (all
# files are full-content "added" patches) as uncommitted changes on an
# empty base commit, then review that.
#
# Env: REVISO_TIER (required: review|audit|style — which product is under test),
# CORPUS_FILE (default eval/corpus/public.jsonl; set it to
# "$REVISO_EVAL_PRIVATE_CORPUS" to run a private-tier case — send those runs
# to eval/runs/private/, which is gitignored), plus everything
# candidate.sh honors.
set -eu
CASE="${1:?usage: gold.sh <case-id> <outdir>}"
OUT="${2:?usage: gold.sh <case-id> <outdir>}"
HERE=$(cd "$(dirname "$0")" && pwd)
# Resolved here, not just in candidate.sh, so an unnamed tier fails before
# the clone and the checkout rather than after them.
. "$HERE/review-tier.sh"
resolve_review_tier
CORPUS_DIR=$(cd "$HERE/../corpus" && pwd)
CORPUS_FILE="${CORPUS_FILE:-$CORPUS_DIR/public.jsonl}"
[ -f "$CORPUS_FILE" ] || { echo "gold.sh: corpus file not found: $CORPUS_FILE" >&2; exit 1; }
# Relative paths inside an entry (labels, fixture) resolve against the corpus
# file's OWN directory, not the repo's. That is what lets a corpus outside the
# repo — the private tier, via CORPUS_FILE="$REVISO_EVAL_PRIVATE_CORPUS" — carry
# its labels beside it. For the default public corpus the two are the same dir,
# so this is a no-op there.
CORPUS_BASE=$(cd "$(dirname "$CORPUS_FILE")" && pwd)
CACHE="$(cd "$HERE/.." && pwd)/.cache/clones"
mkdir -p "$CACHE"
case "${CANDIDATE_HOST:-claude}" in
  claude) mkdir -p "$OUT" ;;
  codex)
    : "${CANDIDATE_CODEX_MODEL:?CANDIDATE_CODEX_MODEL is required}"
    : "${CANDIDATE_CODEX_EFFORT:?CANDIDATE_CODEX_EFFORT is required}" ;;
  *) echo "gold.sh: unknown CANDIDATE_HOST '${CANDIDATE_HOST}' (claude|codex)" >&2; exit 1 ;;
esac

ENTRY=$(jq -c --arg id "$CASE" 'select(.id == $id)' "$CORPUS_FILE")
[ -n "$ENTRY" ] || { echo "gold.sh: case '$CASE' not in $CORPUS_FILE" >&2; exit 1; }
LABELS_REL=$(printf '%s' "$ENTRY" | jq -r '.labels // ""')
[ -n "$LABELS_REL" ] || { echo "gold.sh: case '$CASE' has no \"labels\" field in $CORPUS_FILE — gold mode needs one" >&2; exit 1; }
LABELS="$CORPUS_BASE/$LABELS_REL"
[ -f "$LABELS" ] || { echo "gold.sh: labels file missing: $LABELS" >&2; exit 1; }

WD=$(mktemp -d "${TMPDIR:-/tmp}/reviso-gold-$CASE.XXXXXX")
RWD="$WD"      # where the review actually runs (worktree for real cases)
CDIR=""
cleanup() {
  if [ -n "$CDIR" ] && [ -d "$RWD" ]; then
    git -C "$CDIR" worktree remove --force "$RWD" 2>/dev/null || true
  fi
  rm -rf "$WD"
}
trap cleanup EXIT

if [ "$(printf '%s' "$ENTRY" | jq -r '.synthetic // false')" = "true" ]; then
  # Materialize (design D6): fixture files with status "context" form
  # the base commit — the pre-existing repo a convention-relative lens
  # cites as its baseline — and "added" files land as uncommitted
  # additions, so the working diff equals the fixture's diff.
  FIXTURE="$CORPUS_BASE/$(printf '%s' "$ENTRY" | jq -r '.fixture')"
  git -C "$WD" init -q
  materialize() {  # materialize <status> — write every fixture file of that status
    n=$(jq '.files | length' "$FIXTURE")
    i=0
    while [ "$i" -lt "$n" ]; do
      if [ "$(jq -r ".files[$i].status" "$FIXTURE")" = "$1" ]; then
        fn=$(jq -r ".files[$i].filename" "$FIXTURE")
        mkdir -p "$WD/$(dirname "$fn")"
        # Full-content patch: body = every +line minus the prefix.
        jq -r ".files[$i].patch" "$FIXTURE" \
          | sed -n 's/^+//p' > "$WD/$fn"
      fi
      i=$((i + 1))
    done
  }
  materialize context
  git -C "$WD" add -A
  git -C "$WD" -c user.email=eval@reviso -c user.name=reviso-eval \
    commit -q --allow-empty -m "base"
  materialize added
  BASE=$(git -C "$WD" rev-parse HEAD)
  HEAD_SHA=$BASE   # review scope = uncommitted changes on the base
else
  REPO=$(printf '%s' "$ENTRY" | jq -r '.repo')
  CLONE_URL=$(printf '%s' "$ENTRY" | jq -r '.clone_url')
  BASE=$(printf '%s' "$ENTRY" | jq -r '.base_sha')
  HEAD_SHA=$(printf '%s' "$ENTRY" | jq -r '.head_sha')
  CDIR="$CACHE/$(printf '%s' "$REPO" | tr '/' '__')"
  if [ ! -d "$CDIR" ]; then
    git clone -q --filter=blob:none "$CLONE_URL" "$CDIR"
  fi
  git -C "$CDIR" fetch -q --no-write-fetch-head origin "$BASE" "$HEAD_SHA"
  # A worktree (not a shared clone) so the cache's promisor config still
  # serves lazy blob fetches for the blobless clone during checkout.
  RWD="$WD/repo"
  git -C "$CDIR" worktree add -q --detach "$RWD" "$HEAD_SHA"
  if [ "${CANDIDATE_HOST:-claude}" = "codex" ]; then
    # The read-only candidate cannot lazy-fetch missing blobs. Materialize
    # the reviewed diff and its bounded history before entering the sandbox.
    DIFF_BASE=$(git -C "$RWD" merge-base "$BASE" "$HEAD_SHA")
    git -C "$RWD" diff --no-ext-diff "$DIFF_BASE" "$HEAD_SHA" >/dev/null
    git -C "$RWD" rev-list --objects --no-object-names "$DIFF_BASE..$HEAD_SHA" \
      | git -C "$RWD" cat-file --batch >/dev/null
  fi
fi

# Tier named explicitly at the call site — never left to whatever the
# environment happened to carry in.
if [ "${CANDIDATE_HOST:-claude}" = "codex" ]; then
  "${REVISO_PYTHON:-python3}" "$HERE/candidate-codex.py" "$RWD" "$BASE" "$HEAD_SHA" "$OUT" \
    --tier "$REVIEW_TIER" --model "$CANDIDATE_CODEX_MODEL" --effort "$CANDIDATE_CODEX_EFFORT" \
    --timeout "${CANDIDATE_TIMEOUT:-900}"
  if [ "$(jq -r '.status' "$OUT/meta.json")" != "returned" ]; then
    echo "gold.sh: incomplete Codex coverage — not scored" >&2
    exit 1
  fi
else
  REVISO_TIER="$REVIEW_TIER" sh "$HERE/candidate.sh" "$RWD" "$BASE" "$HEAD_SHA" "$OUT"
fi

# Judge against the labels (tiering + metrics live in gold-judge.sh so a
# recorded run can be re-judged when calibration moves).
sh "$HERE/gold-judge.sh" "$LABELS" "$OUT/candidate.json" "$OUT"

jq -r --arg t "$REVIEW_TIER" 'if .expected_clean then
    "gold[\($t)](clean): \(.clean_case_fp_count) false positive(s)"
  else
    "gold[\($t)] recall (correctness): \(.metrics.gold_recall_correctness // "n/a")%  (\(.metrics.matched_correctness_count)/\(.metrics.gold_correctness_count))  precision proxy: \(.metrics.precision_proxy_pct // "n/a")%  promotion candidates: \(.promotion_candidates | length)"
  end' "$OUT/gold-judge.json" >&2
