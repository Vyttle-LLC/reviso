#!/bin/sh
# review-tier.sh — resolve which Reviso REVIEW TIER is under test.
# Sourced, never executed. Not to be confused with tiers.sh, which tiers
# FINDINGS (correctness vs cleanup); this file names the PRODUCT being
# measured.
#
# REVISO_TIER is required and has no default. A default is what produced
# the situation this file exists to end: candidate.sh hardcoded
# /reviso:review, every caller inherited that one tier, no artifact
# recorded it, and so a 48% recall figure measured the single-pass review
# while being read as "Reviso's recall". Mirrors baseline.sh's refusal of
# an unpinned upstream level.
#
# Sets REVIEW_TIER (review|audit) and REVIEW_TIER_CMD (its slash command).
resolve_review_tier() {
  case "${REVISO_TIER:-}" in
    review) REVIEW_TIER=review; REVIEW_TIER_CMD='/reviso:review' ;;
    audit)  REVIEW_TIER=audit;  REVIEW_TIER_CMD='/reviso:audit' ;;
    "")
      echo "${0##*/}: REVISO_TIER is required and has no default — set it to 'review' or 'audit'" >&2
      exit 1 ;;
    *)
      echo "${0##*/}: unknown REVISO_TIER '$REVISO_TIER' — accepted values: review, audit" >&2
      exit 1 ;;
  esac
}
