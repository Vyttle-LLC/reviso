## Reviso review — HEAD (detached) vs 85737f52b5 (1 commit, 8 files)

Found 2 issues:

**1. [P0][conf 85] Recovery codes written to user storage lose one-time-use, hashing, and metadata — `server-spi-private/src/main/java/org/keycloak/utils/CredentialHelper.java:115`**

`createRecoveryCodesCredential` flattens the fully-built `RecoveryAuthnCodesCredentialModel` (RS512-hashed codes, per-code ordinal, remaining-count, `generatedAt`, `userLabel`) into a bare `UserCredentialModel("", type, jsonArrayOfRawCodes)` and, if the user storage accepts it (`CredentialHelper.java:125`), discards the model entirely. Everything the model encoded is dropped at the storage boundary, and nothing on the Keycloak side re-establishes it.

Failure: a federated user configures recovery codes; the store accepts them, so no local credential exists. At login, `UserCredentialManager.isValid` hands the input to the storage validator, and `UserCredentialManager.validate` (`model/storage/.../UserCredentialManager.java:271`) removes it from `toValidate` on success — so `RecoveryAuthnCodesCredentialProvider.isValid`, the only caller of `removeRecoveryAuthnCode()` + `updateStoredCredential()`, never runs. The code is never consumed. Meanwhile `RecoveryAuthnCodesUtils.getCredential` (`server-spi/src/main/java/org/keycloak/models/utils/RecoveryAuthnCodesUtils.java:56`) prefers the federated credential, which the provider rebuilds from the full raw list on every read, so `getNextRecoveryAuthnCode()` in `RecoveryAuthnCodeInputLoginBean` always renders "#1" and `allCodesUsed()` in `RecoveryAuthnCodesFormAuthenticator:85` is never true — the regenerate required-action never fires either. The reference implementation added in this same PR confirms the semantics: `BackwardsCompatibilityUserStorage.java:340` does `generatedKeys.stream().anyMatch(key -> key.equals(input.getChallengeResponse()))` — any of the 12 raw codes, accepted forever, stored in plaintext. One leaked recovery code becomes a permanent second-factor bypass. The new test can't catch this: it logs in once and never re-enters a used code.

Fix: don't delegate one-time-use to an SPI that has no contract for it. Either keep the authoritative `RecoveryAuthnCodesCredentialModel` in local storage and use user storage only for validation, or extend `CredentialInputUpdater` with an explicit recovery-codes contract (consume-on-use, hash-at-rest, carry `generatedAt`/`userLabel`) and document it — then have `RecoveryAuthnCodesFormAuthenticator` verify the remaining count actually decreased after a successful federated validation. At minimum, add a test that replays an already-used code against user storage and asserts it is rejected.
(bugs, history)

**2. [P2][conf 80] Test helpers copied verbatim from `RecoveryAuthnCodesAuthenticatorTest`, typo and dead config included — `testsuite/integration-arquillian/tests/base/src/test/java/org/keycloak/testsuite/federation/storage/BackwardsCompatibilityUserStorageTest.java:123`**

`configureBrowserFlowWithRecoveryAuthnCodes` (:123) and `enterRecoveryCodes` (:476) are near-verbatim copies of `testsuite/integration-arquillian/tests/base/src/test/java/org/keycloak/testsuite/forms/RecoveryAuthnCodesAuthenticatorTest.java:123` and `:299`, carrying over the `"delayed-suthenticator-config"` typo and a `delayed-authenticator` execution that only ever exists to support that file's concurrent-login test (`delay=1000`); here it is always called with `delay=0`, so it adds a `DelayedAuthenticatorFactory` dependency to the flow for nothing.

Failure: the two copies drift — a fix to the flow shape in one test silently leaves the other broken, and the dead `delayed-authenticator` step makes this test fail for reasons unrelated to user-storage recovery codes if that provider changes.

Fix: drop the `delayed-authenticator` execution and the `delay` parameter from this copy (it is unused here), and lift the shared `enterRecoveryCodes` helper into a common location — the existing one is `private`, so promote it rather than duplicating.
(slop)

Checked: bugs, conventions, history, comments, slop. No `CLAUDE.md`/`AGENTS.md` found in the repo root or in any changed file's directory. The deterministic detector suite was not approved to run, so its findings are absent from this report.
Skipped: nothing.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
