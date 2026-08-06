#!/bin/sh
# Reviso feedback — the deterministic payload builder (docs/feedback.md is
# the contract this script implements; SECURITY.md makes violating it a
# vulnerability, not a bug).
#
# The model never composes an outbound payload: every tier-1 field is an
# enum or a strictly patterned single token, validated here, assembled
# here. Free text has nowhere to enter a tier-1 payload. Tier 2 never
# posts — it only prints a prefilled issue-form URL for the user's browser.
#
# Usage:
#   build-payload.sh meta  --lens <lens> --severity <P0|P1|P2>
#                          --confidence <80s|90s|100> --reason <reason>
#                          --command <review|audit> --model <model-id>
#                          [--detector <id>] [--send]
#   build-payload.sh tier2 --command <review|audit>    (finding text on stdin)
#
# meta prints the exact title + body; with --send it then posts that exact
# payload (same deterministic build — what was shown is what is sent).
# Exit: 0 built/sent · 1 usage or validation · 2 backstop veto · 3 gh missing.
set -eu

# The one permitted destination. Changing this constant changes the
# security contract — see SECURITY.md before you do.
REPO="Vyttle-LLC/reviso"
FORM_URL="https://github.com/$REPO/issues/new?template=false-positive.yml"

die()  { printf 'build-payload: %s\n' "$1" >&2; exit 1; }
veto() { printf 'build-payload: refusing: %s\n' "$1" >&2; exit 2; }

oneof() { # oneof <name> <value> <allowed>...
  _n=$1; _v=$2; shift 2
  for _a in "$@"; do
    if [ "$_v" = "$_a" ]; then return 0; fi
  done
  die "$_n must be one of: $* (got: ${_v:-nothing})"
}

patt() { # patt <name> <value> <anchored ERE>
  if ! printf '%s\n' "$2" | grep -Eq "^$3\$"; then
    die "$1 is malformed (got: ${2:-nothing})"
  fi
}

# Backstops, belt and braces: construction already prevents every one of
# these, so a hit means a bug upstream — veto loudly, send nothing.
scan() { # scan <text> <byte-cap>
  if [ "$(printf '%s' "$1" | wc -c)" -gt "$2" ]; then
    veto "payload exceeds $2 bytes"
  fi
  if printf '%s\n' "$1" | grep -q '```'; then
    veto "code fence in payload"
  fi
  if printf '%s\n' "$1" | grep -Eq '^(@@ |\+\+\+ |--- |diff --git )'; then
    veto "diff marker in payload"
  fi
  if printf '%s\n' "$1" | grep -Eq \
    'AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}|github_pat_|xox[baprs]-|sk-[A-Za-z0-9]{16,}|AIza[0-9A-Za-z_-]{20,}|sb_(secret|publishable)_|BEGIN [A-Z ]*PRIVATE KEY'
  then
    veto "secret-shaped token in payload"
  fi
  if printf '%s\n' "$1" | grep -Eq '[A-Za-z0-9+=_-]{40,}'; then
    veto "high-entropy token in payload"
  fi
}

# Full percent-encoding of every byte: portable, and correct for any input.
enc() { printf '%s' "$1" | od -An -v -tx1 | awk '{for(i=1;i<=NF;i++) printf "%%%s", $i}'; }

HERE=$(cd "$(dirname "$0")" && pwd)
VERSION=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' \
  "$HERE/../../../.claude-plugin/plugin.json" | head -n 1)
patt "plugin version" "$VERSION" '[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?'

MODE=${1-}
[ -n "$MODE" ] || die "usage: build-payload.sh meta|tier2 ..."
shift

LENS= SEV= CONF= REASON= CMD= MODEL= DETECTOR= SEND=0
while [ $# -gt 0 ]; do
  case $1 in
    --send) SEND=1; shift; continue ;;
    --lens|--severity|--confidence|--reason|--command|--model|--detector)
      [ $# -ge 2 ] || die "$1 needs a value" ;;
    *) die "unknown flag: $1" ;;
  esac
  case $1 in
    --lens)       LENS=$2 ;;
    --severity)   SEV=$2 ;;
    --confidence) CONF=$2 ;;
    --reason)     REASON=$2 ;;
    --command)    CMD=$2 ;;
    --model)      MODEL=$2 ;;
    --detector)   DETECTOR=$2 ;;
  esac
  shift 2
done

oneof "--command" "$CMD" review audit

case $MODE in
meta)
  oneof "--lens" "$LENS" bugs conventions history prior-reviews comments slop deterministic
  oneof "--severity" "$SEV" P0 P1 P2
  oneof "--confidence" "$CONF" 80s 90s 100
  oneof "--reason" "$REASON" codebase-convention upstream-guarantee \
    deliberate-choice linter-territory wrong-on-facts other
  patt "--model" "$MODEL" '[a-z][a-z0-9-]{2,39}'
  if [ "$LENS" = deterministic ]; then
    [ -n "$DETECTOR" ] || die "lens 'deterministic' requires --detector"
    [ "$CONF" = 100 ] || die "deterministic findings report at confidence 100"
    # Keep in sync with detectors/detect.awk.
    oneof "--detector" "$DETECTOR" conflict testfocus
  elif [ -n "$DETECTOR" ]; then
    die "--detector only applies to --lens deterministic"
  fi

  # Field patterns forbid '/' and '.', so no payload field can carry a path
  # into the user's repository tree. Re-checked here anyway.
  for _v in "$LENS" "$SEV" "$CONF" "$REASON" "$CMD" "$MODEL" "$DETECTOR"; do
    case $_v in
      */*|*.*) veto "path-shaped field value: $_v" ;;
    esac
  done

  TITLE="[FP][meta] $LENS $SEV $REASON"
  BODY="Tier-1 false-positive report — metadata only, built and validated by
build-payload.sh under the docs/feedback.md contract. No free text.

- lens: $LENS
- detector: ${DETECTOR:-none}
- severity: $SEV
- confidence: $CONF
- reason: $REASON
- command: /reviso:$CMD
- plugin: $VERSION
- model: $MODEL"

  scan "$TITLE
$BODY" 600

  # Print before send, every time. The send re-uses these exact strings.
  printf '%s\n\n%s\n' "$TITLE" "$BODY"

  if [ "$SEND" = 1 ]; then
    if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
      printf 'build-payload: gh unavailable or unauthenticated; file manually:\n%s\n' \
        "$FORM_URL" >&2
      exit 3
    fi
    gh issue create --repo "$REPO" --title "$TITLE" --body "$BODY" \
      --label false-positive --label eval-candidate
  fi
  ;;

tier2)
  FINDING=$(cat)
  [ -n "$FINDING" ] || die "tier2 expects the finding text on stdin"
  # Same secret/entropy backstops before the text rides a URL; the cap is
  # what fits a browser address bar once fully percent-encoded.
  scan "$FINDING" 2000
  printf '%s&command=%s&version=%s&finding=%s\n' \
    "$FORM_URL" "$(enc "/reviso:$CMD")" "$(enc "$VERSION")" "$(enc "$FINDING")"
  ;;

*)
  die "unknown mode: $MODE (expected meta or tier2)"
  ;;
esac
