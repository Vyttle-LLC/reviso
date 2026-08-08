## Reviso review — HEAD vs f3c8e8f (1 commit, 49 files)

Found 6 issues:

1. **[P1][conf 95] `totpStep1` rewritten with wrong-language text in three locale bundles** — `themes/src/main/resources-community/theme/base/account/messages/messages_lt.properties:101`
   Failure: The Lithuanian bundles now carry **Italian** text — `totpStep1=Installa una delle seguenti applicazioni sul tuo cellulare:` (same string at `themes/src/main/resources-community/theme/base/login/messages/messages_lt.properties:71`). Compare `messages_it.properties:138` = `Installa una delle seguenti applicazioni sul tuo dispositivo mobile`. Separately, `themes/src/main/resources-community/theme/base/account/messages/messages_zh_CN.properties:112` now reads `在您的手機上安裝以下應用程式之一：` — Traditional Chinese (手機/應用程式) inside a Simplified bundle whose neighbouring lines are Simplified (`打开应用扫描二维码`); the login zh_CN file keeps proper Simplified text (`在您的移动设备中安装以下任意一个应用：`). Lithuanian and Simplified-Chinese users see the OTP setup step in a language they don't read.
   Fix: Translate the new English source (`Install one of the following applications on your mobile:`) into Lithuanian for both files, and into Simplified Chinese for the zh_CN account file (e.g. `在您的手机上安装以下应用程序之一：`).
   (bugs)

2. **[P1][conf 90] Java MessageFormat syntax substituted into i18next bundles — placeholders will render literally** — `js/apps/account-ui/maven-resources/theme/keycloak.v3/account/messages/messages_en.properties:188`
   Failure: `error-invalid-multivalued-size` changed from `Attribute {{0}} must have at least {{1}} and at most {{2}} value(s).` to `Attribute {0} ... {2,choice,0#values|1#value|1<values}.` in both React consoles (also `js/apps/admin-ui/maven-resources/theme/keycloak.v2/admin/messages/messages_en.properties:3138`). These bundles are consumed by i18next with default interpolation (`js/apps/account-ui/src/i18n.ts:25`), which only expands `{{n}}` and has no `choice` format. Every sibling validation key in the same file uses `{{0}}`/`{{1}}`/`{{2}}` (`messages_en.properties:2989-3009`), as does every other locale for this same key (`messages_fr.properties:188`, `messages_pl.properties:188`, …). A user hitting a multivalued-size violation will see the literal string `Attribute {0} must have at least {1} and at most {2} {2,choice,0#values|1#value|1<values}.`
   Fix: Revert these two JS bundles to `{{0}}`/`{{1}}`/`{{2}}` (with `value(s)` or i18next plurals). The `{n}` + `choice` form is correct only for the server-side FreeMarker bundles (`themes/src/main/resources/theme/base/{admin,login}/messages/messages_en.properties`), which this commit also updated.
   (bugs; history — the JS bundles have used `{{n}}` since introduction)

3. **[P2][conf 88] "Illegal HTML" is reported for legal HTML that merely serializes differently** — `misc/theme-verifier/src/main/java/org/keycloak/themeverifier/VerifyMessageProperties.java:111`
   Failure: The check compares the source string to the sanitizer's *output*, so it enforces OWASP's serialization, not safety. `<br/>` round-trips as `<br />`, which is why this commit had to rewrite `<br/>` in ~20 locale files. The next contributor who writes `<br/>` gets a build failure reading `Illegal HTML in key webauthn-error-registration for file …: '/' vs. ' '` — the prefix/suffix stripping at lines 102-109 reduces the diff to a single slash vs. a single space, which names neither the tag nor the actual problem.
   Fix: Normalize both sides before comparing (e.g. run `value` through the same policy-free serialization, or compare `policy.sanitize(value)` against `policy.sanitize(sanitized)`), so only genuinely stripped markup is reported; failing that, include the full original and sanitized values in the message rather than the minimized diff.
   (bugs, comments)

4. **[P2][conf 90] Anchor-mismatch failures are unattributable, and `key` is accepted but never used** — `misc/theme-verifier/src/main/java/org/keycloak/themeverifier/VerifyMessageProperties.java:157`
   Failure: `messages.add("Didn't find anchor tag " + matcher.group() + " in original string")` omits both the file and the key, unlike every other message in this class (lines 111, 194). `ThemeVerifierMojo:55` concatenates messages from every file in the module into one `MojoFailureException`, so a CI failure across ~200 locale files reports only `Didn't find anchor tag <a href="…"> in original string` with no way to find which bundle to edit. `santizeAnchors(String key, …)` takes `key` at line 150 precisely for this and then never reads it.
   Fix: `messages.add("Didn't find anchor tag " + matcher.group() + " in key " + key + " for file " + file + " in original string");` — matching the format used at line 111. (Method name is also misspelled: `santizeAnchors` → `sanitizeAnchors`.)
   (bugs, slop)

5. **[P2][conf 85] Policy factories and `HTML_TAGS` are mutable non-static fields rebuilt for every file** — `misc/theme-verifier/src/main/java/org/keycloak/themeverifier/VerifyMessageProperties.java:58`
   Failure: `POLICY_SOME_HTML` (:58), `POLICY_NO_HTML` (:63) and `HTML_TAGS` (:139) are package-private, non-static, non-final instance fields with constant-style names, declared between methods. `ThemeVerifierMojo:51` constructs one `VerifyMessageProperties` per message file, so each of the ~200 bundles recompiles the regex and rebuilds two `PolicyFactory` instances. `ANCHOR_PATTERN` twelve lines below (:145) is correctly `private static final` — the same diff uses both conventions.
   Fix: Make all three `private static final` and move them to the top of the class with the other fields.
   (slop, conventions)

6. **[P2][conf 82] No test asserts that a valid bundle produces zero findings** — `misc/theme-verifier/src/test/java/org/keycloak/themeverifier/VerifyMessagePropertiesTest.java:36`
   Failure: All four tests assert `hasItem(containsString(...))`, and the pre-existing duplicate-keys assertion was loosened from `Matchers.contains` to `Matchers.hasItem` (:33). Nothing asserts the negative case, so a regression that makes `verifySafeHtml` flag *every* message — allowed tags, `{0}` placeholders, `{{ }}` double braces, matching anchors — passes the suite and only surfaces as a build failure across the whole `themes` module. This commit's ~20 files of `<br/>` churn is exactly the kind of false positive such a test would pin down.
   Fix: Add a fixture pair (e.g. `valid_en.properties` / `valid_de.properties`) exercising `<b>`, `<br />`, a matching `<a href="{0}">`, `{0}` and `{{0}}`, and assert `verify()` returns an empty list.
   (conventions, test-coverage)

Checked: bugs, conventions, history, comments, slop. The deterministic detector suite was **not** run — the `detectors/run.sh` invocation was not approved, so no `deterministic`-tagged findings are included.
Skipped: nothing; the ~20 locale files whose only change is `<br/>` → `<br />` were reviewed as a group under finding 3.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
