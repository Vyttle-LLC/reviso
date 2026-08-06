#!/bin/sh
# extract-builtin.sh [binary] [outfile] — extract the built-in code-review
# skill text embedded in the Claude Code CLI binary, for LOCAL inspection.
#
# The upstream review Reviso benchmarks against ships inside the CLI, not as
# a plugin file, so drift detection is behavioral (re-run corpus baselines on
# a CLI version roll — see eval/README.md). This script exists for the human
# step: seeing WHAT changed. Its output is proprietary Anthropic prompt text
# and MUST NOT be committed — it writes into eval/reference/private/
# (gitignored). The repo carries only this method, the per-version SHA-256 of
# the extraction, and a factual structural summary (builtin-skill-notes.md).
#
# Extraction is heuristic: the binary interleaves UTF-8 and UTF-16LE string
# constants, and template placeholders fragment the text. The output is a
# faithful ordered dump of the review-related fragments, not a verbatim
# document. The hash is stable for a given (binary, script) pair — that's
# what makes it a drift fingerprint.
set -eu
BIN="${1:-$(readlink -f "$(command -v claude)")}"
HERE=$(cd "$(dirname "$0")" && pwd)
VERSION=$("$BIN" --version 2>/dev/null | awk '{print $1}')
OUTFILE="${2:-$HERE/private/builtin-skill-${VERSION:-unknown}.txt}"
mkdir -p "$(dirname "$OUTFILE")"

python3 - "$BIN" "$OUTFILE" <<'PYEOF'
import re, sys, hashlib

bin_path, out_path = sys.argv[1], sys.argv[2]
data = open(bin_path, 'rb').read()

# Broad markers select what lands in the LOCAL dump (context included).
BROAD = ['code-review', 'ReportFindings']
# Tight markers select what the drift fingerprint hashes: phrases unique to
# the review skill's own instruction text. Broad blocks shift between builds
# for unrelated reasons (neighboring prose, fragmentation), so hashing them
# would cry drift on every release.
TIGHT = [
    'CONFIRMED / PLAUSIBLE / REFUTED',
    'removed-behavior', 'cross-file tracer', 'language-pitfall',
    'wrapper/proxy', 'correctness angle', 'cleanup angle',
    'finder angle', 'single-pass inline', 'Verify (1-vote',
    'reviewing for **recall**', 'reviewing for **precision**',
]

# Cap block size: a marker hit inside the minified JS bundle would otherwise
# swallow the whole multi-MB bundle as one "block", which both bloats the
# dump and changes every release. Skill-text fragments are a few KB at most.
MAX_BLOCK = 20_000

blocks = []
for pat, dec in ((rb'(?:[\x20-\x7e\n\r\t]\x00){40,}', 'utf-16le'),
                 (rb'[\x20-\x7e\n\r\t]{40,}', 'utf-8')):
    for m in re.finditer(pat, data):
        s = m.group().decode(dec, errors='replace')
        if len(s) > MAX_BLOCK:
            continue
        tight = any(k in s for k in TIGHT)
        if tight or any(k in s for k in BROAD):
            blocks.append((m.start(), tight, s))

blocks.sort()
text = '\n⟪⋄⟫\n'.join(s for _, _, s in blocks)
open(out_path, 'w').write(text)
# Fingerprint: tight blocks only, order-independent (offsets move every
# build), deduplicated (the binary stores some strings twice).
core = sorted({s for _, tight, s in blocks if tight})
digest = hashlib.sha256('\n⟪⋄⟫\n'.join(core).encode()).hexdigest()
print(f"blocks: {len(blocks)} (fingerprinted: {len(core)})")
print(f"sha256: {digest}")
PYEOF

echo "cli_version: ${VERSION:-unknown}"
echo "written (LOCAL ONLY — do not commit): $OUTFILE"
