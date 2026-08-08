## Reviso review — HEAD (detached) vs 10aca55523 (1 commit, 12 files)

Found 2 issues:

1. **[P1][conf 85] Removing the multi-provider guard makes an ambiguous crypto classpath silently pick a provider instead of failing** — `common/src/main/java/org/keycloak/common/crypto/CryptoIntegration.java:57`
   Failure: `DefaultCryptoProvider`, `WildFlyElytronProvider`, and `FIPS1402Provider` all return `order() == 200` (`crypto/default/.../DefaultCryptoProvider.java:83`, `crypto/elytron/.../WildFlyElytronProvider.java:76`, `crypto/fips1402/.../FIPS1402Provider.java:114`). `sorted()` is stable, so with two of them on the classpath the winner is whichever `ServiceLoader` happens to yield first — i.e. jar order. A FIPS deployment that accidentally drags in `keycloak-crypto-default` now boots quietly on non-FIPS BouncyCastle; before 79d11c4890 it failed at startup with "Multiple crypto providers loaded... Make sure only one cryptoProvider available on the classpath" (guard added deliberately in a8db79a68c). The only trace is a `debug`-level "Ignored crypto providers" line, off by default.
   Fix: only tolerate ambiguity when the ordering actually resolves it — keep the hard failure for an unresolved tie:
   ```java
   if (foundProviders.size() > 1 && foundProviders.get(0).order() == foundProviders.get(1).order()) {
       throw new IllegalStateException("Multiple crypto providers with the same order loaded with the classLoader: "
               + classLoader + ". Available providers: " + foundProviders);
   }
   ```
   (bugs, history)

2. **[P2][conf 100] Dead code: two ASN.1 encoders are built and discarded** — `authz/client/src/main/java/org/keycloak/authorization/client/util/crypto/AuthzClientCryptoProvider.java:114`
   Failure: lines 114–115 create two `ASN1Encoder` instances, write `rBigInteger`/`sBigInteger` into them, and drop the results on the floor; the return statement at 117–121 constructs four fresh encoders and does the real work. Harmless at runtime, but it reads as if the values are needed and invites a future edit to "reuse" them.
   Fix: delete lines 114–115.
   (slop)

Checked: bugs, conventions, history, comments, slop.
Skipped: whitespace-only hunks in `CryptoProvider.java`, `DefaultCryptoProvider.java`, `FIPS1402Provider.java`; `authz/client/pom.xml` test-scope dependency additions; license headers. No `CLAUDE.md`/`AGENTS.md` exists in this repo, so the conventions lens ran against surrounding code style only. The deterministic detector suite did not run — the `sh .../detectors/run.sh` invocation was not approved, so detector findings are absent from this report.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
