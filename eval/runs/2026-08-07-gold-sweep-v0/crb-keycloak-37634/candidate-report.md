## Reviso review — HEAD vs c22f768 (2 commits, 28 files)

Found 3 issues:

1. **[P1][conf 92] `isAccessTokenId` matcher is inverted and off-by-one — it never checks the grant shortcut** — `testsuite/integration-arquillian/tests/base/src/test/java/org/keycloak/testsuite/AssertEvents.java:483`
   Failure: the encoding is `sessionType(2) + tokenType(2) + grantType(2)`, so the grant shortcut lives at `[4,6)`, not `[3,5)`; and the guard returns `false` when the substring *equals* the expected shortcut instead of when it differs. For a real code-to-token id `onrtac:<uuid>`, `substring(3,5)` is `"ta"`, which never equals `"ac"`, so the check falls through and only the UUID part is validated. All four call sites (lines 145, 173, 182, 244) therefore assert nothing about the grant type — the exact thing commit `daffb05b5a` rewrote them to assert. The previous form `if (!items[0].contains("gt." + expectedGrantShortcut)) return false;` was correct. Conversely, any grant whose shortcut happens to collide with chars 3–4 would fail spuriously.
   Fix: `if (!items[0].substring(4, 6).equals(expectedGrantShortcut)) return false;` and fix the comment to say the shortcut starts at index 4. Consider guarding `items[0].length() == 6` first to avoid `StringIndexOutOfBoundsException` on malformed ids.
   (bugs; enforcement-vs-claim)

2. **[P1][conf 85] New `getShortcut()` on the `OAuth2GrantTypeFactory` SPI has no `default`, so existing grant-type extensions die at startup** — `server-spi-private/src/main/java/org/keycloak/protocol/oidc/grants/OAuth2GrantTypeFactory.java:33`
   Failure: `DefaultTokenContextEncoderProviderFactory.postInit` (line 74) casts and calls `gtf.getShortcut()` on *every* registered `OAuth2GrantType` factory during boot. A third-party grant provider jar compiled against the previous SPI throws `AbstractMethodError` there, taking down server startup rather than failing only on that grant. The immediately preceding commit on this same SPI (`4ad4a8d37b`) added `getSupportedMultivaluedRequestParameters()` to `OAuth2GrantType` as a `default` method for exactly this reason. Same file, related anchor: the `Context(Context context)` copy constructor was deleted from the public `OAuth2GrantType.Context` class (it has no in-tree callers, but it is SPI surface, added by `983680ce0e`).
   Fix: give it a default — e.g. `default String getShortcut() { return DefaultTokenContextEncoderProvider.UNKNOWN; }` — or have `postInit`/`getShortcutByGrantType` tolerate a missing shortcut by falling back to `"na"` instead of propagating. If the hard break is intentional, keep it but restore the copy constructor or note the removal.
   (conventions; history)

3. **[P2][conf 90] `rawTokenId` null-check is a copy-paste of the `grantType` check, so it validates nothing** — `services/src/main/java/org/keycloak/protocol/oidc/encode/AccessTokenContext.java:73`
   Failure: `Objects.requireNonNull(grantType, "Null rawTokenId not allowed")` re-checks `grantType`. A `null` `rawTokenId` passes construction and `encodeTokenId` then emits a token id of `"onrtac:null"`, which round-trips through `getTokenContextFromTokenId` as the literal string `"null"` instead of failing fast where the constructor claims it does.
   Fix: `Objects.requireNonNull(rawTokenId, "Null rawTokenId not allowed");`
   (bugs; enforcement-vs-claim)

Checked: bugs, conventions, history, comments, slop.
Skipped: license-header-only content in the new files, `META-INF/services/*` registration entries, and the deterministic detector suite (its `run.sh` invocation was not approved, so no `deterministic` findings are included).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
