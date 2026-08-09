# tiers.sh — the one definition of which finding categories Reviso gates.
# Sourced by judge.sh (parity) and gold.sh (gold). Not executable on its own.
#
# The tier split is named correctness/cleanup for historical reasons, but what
# it actually encodes is IN-LANE vs OUT-OF-LANE: does Reviso claim to ship this
# kind of finding? In-lane misses are regressions and are listed individually;
# out-of-lane misses are informational, because not shipping them is the
# product working as designed.
#
# That distinction is why `duplication` is NOT in this list. Reviso shipped the
# duplication lens in 0.3.0 with a calibrated bar, so a duplication finding it
# misses is a real miss — in gold mode against a label, and in parity mode
# against the built-in. Before 0.3.0 the lane was gated and the category
# belonged here.
#
# Expanding this list is a calibration decision, recorded in eval/calibration/:
# observability and deploy-safety came from the sagechat-15 hand labels
# (2026-08-06, all such findings ruled out-of-lane). Removing a category is the
# same kind of decision and needs the same evidence — a lens that ships it.
CLEANUP_RE='^(simplification|efficiency|reuse|altitude|conventions|test-coverage|observability|deploy-safety)$'
