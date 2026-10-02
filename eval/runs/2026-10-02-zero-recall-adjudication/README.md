# Zero-recall CRB adjudication — 2026-10-02

Source: the 15 cases listed in issue #13, from the 2026-08-07 gold sweep.
All 35 imported findings now carry a dated ruling and pinned source evidence
in `eval/corpus/labels/`. Original descriptions and CRB categories remain
intact. The machine-readable index is
`eval/calibration/adjudication-2026-10-02.json`.

| Disposition | Findings |
| --- | --- |
| Eligible correctness defects | 9 |
| Policy-excluded | 17 |
| Label-wrong / insufficiently specified | 9 |

The historical outputs are re-judged here, without rerunning either the
candidate or matcher. The original sweep remains untouched. After the
exclusions and one category correction, the recorded candidate matched
**1 of 9 eligible correctness findings** in this deliberately selected
zero-recall cluster. This is not full-corpus recall, a current-release
result, or a validation of the old Claude matcher.

The recovered match is Grafana 97529's unlocked cache iteration: the
candidate reported it, but the imported label called a possible map
read/write panic `efficiency`. Its normalized category is now correctness;
`imported_category` preserves the old mapping.

## Rulings that change the interpretation

- Grafana 76186: the default old instrumentation middleware already
  dereferenced nil requests, and the contextual log provider supplies
  `traceID`. Neither label establishes the claimed new regression.
- Grafana 79265: the count-then-insert race remains eligible. Device-limit
  rejection is intentional. The alleged compile failure is false: the
  vendored Xorm session accepts `Exec(sqlOrArgs ...any)`.
- Grafana 90939 and Sentry 80528: the cache-error assignment and wrong
  returned config predate the changes. A latent defect moved unchanged
  is excluded by Reviso's changed-behavior policy.
- Keycloak 36880: resource-server and client IDs are equal in the pinned
  adapter. The cited role-mapping consumer runs only with V1 enabled,
  while the new implementation runs under mutually exclusive V2. These
  labels do not establish reachable regressions. The cleanup flag remains
  eligible.
- Sentry 95633: `.python-version` pins 3.13.1, which has `Queue.shutdown`.
  Test constants and documentation cleanup do not become correctness
  defects merely because the importer mapped them to `bug`.
- Sentry greptile-3: a tuple of integer IDs is not randomized by
  `PYTHONHASHSEED`; the label assumes string-hash behavior. The missing
  zero sample rate and wrong scoped dataset remain eligible defects.
- Sentry greptile-5: the detector-type key is unchanged context. The
  event-ID pairing defect is real: the pinned `NodeStorage.get_multi`
  implementation appends cached entries after uncached ones, so partial
  cache hits reorder the values before the caller zips them with IDs.
- Discourse graphite-9: locale loading already holds `LOAD_MUTEX` and
  rechecks membership. The changed callers use canonical symbol locales;
  neither short label identifies a new valid-input failure.

Two source-based checks supplemented inspection. Executing the pinned
`get_multi` method with A cached and B uncached returned B then A, pairing
the input IDs with the wrong payloads. Integer-tuple hashes were identical
in separate Python processes under hash seeds 1 and 99. No upstream code
is vendored into tracked artifacts.

## Judge behavior

Excluded gold remains visible in `excluded_gold`, outside matching and
the denominator. Original indices are retained for replaying recorded
matches. Entirely excluded cases are unscored, not expected-clean:
candidate-only findings still require verification before being called
wins or false positives. The judge rejects unknown adjudication statuses.

The 9 eligible findings are a starting point for the audit comparison,
not evidence that the current workflow still misses them. Measure both
tiers on the same pinned changes before deciding whether deeper review or
new detection angles are needed.
