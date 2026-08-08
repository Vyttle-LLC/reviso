## Reviso review — HEAD (detached, `feat/2fa-backup-codes`) vs `efa6d46` (21 commits, 16 files)

Note: the deterministic detector suite was not run — the `sh .../detectors/run.sh` call was declined at the permission prompt. Findings below are from manual review only.

Found 5 issues:

1. **[P0][conf 90] Backup-code login skips the password check entirely — `packages/features/auth/lib/next-auth-options.ts:131`**
   Failure: password verification at line 121 is gated on `!credentials.totpCode`, and the new backup-code branch at line 131 runs *before* the TOTP branch and never re-checks the password. An attacker who has only a leaked backup code (they are downloaded to `~/Downloads/cal-backup-codes.txt`, copied to a clipboard, or printed) posts `{email: victim, password: "", totpCode: "000000", backupCode: "abcde-12345"}`. Line 121 is skipped because `totpCode` is truthy, line 131 is taken because `backupCode` is truthy, the arbitrary `totpCode` is never validated, and a session is issued. A second factor that is stored at rest becomes a complete single-factor credential.
   Fix: verify the password inside the backup-code branch before comparing codes, e.g. at the top of the `user.twoFactorEnabled && credentials.backupCode` block:
   ```ts
   if (user.password) {
     if (!(await verifyPassword(credentials.password, user.password)))
       throw new Error(ErrorCode.IncorrectEmailPassword);
   }
   ```
   (or widen line 121 to `if (user.password && (!credentials.totpCode || credentials.backupCode))`). Note the same ordering exists in `apps/web/pages/api/auth/two-factor/totp/disable.ts:48`, but there the password is checked unconditionally first, so only the login path is exploitable.
   (bugs)

2. **[P1][conf 90] Dismissing the backup-codes dialog destroys the only copy of the codes — `apps/web/components/settings/EnableTwoFactorModal.tsx:135`**
   Failure: `handleEnable` now sets `SetupStep.DisplayBackupCodes` instead of calling `onEnable()`. 2FA is already enabled server-side at this point. `DialogContent` (`packages/ui/components/dialog/Dialog.tsx:85`) passes nothing to `DialogPrimitive.Content` to block Radix's default Escape / outside-click dismissal, and only the "Close" button (line 266) calls `onEnable()`. A user who hits Escape or clicks the overlay before downloading/copying loses the codes permanently — there is no regenerate or re-display endpoint anywhere (`backupCodes` is only written in `setup.ts`), so the sole recovery is disabling 2FA with the authenticator they may not have. The same dismissal also skips `utils.viewer.me.invalidate()`, so the settings switch reads "Disabled" while 2FA is on until the page is reloaded.
   Fix: pass `onEscapeKeyDown`/`onPointerDownOutside` handlers that `preventDefault()` while `step === SetupStep.DisplayBackupCodes`, and/or call `onEnable()` from `onOpenChange` when that step is active so the parent state stays in sync. Longer term, add a "regenerate backup codes" action so this is not a one-shot.
   (bugs)

3. **[P2][conf 85] `missing_backup_codes` tells users to do something the UI doesn't offer — `apps/web/public/static/locales/en/common.json:2019`**
   Failure: every user who enabled 2FA before this migration has `backupCodes = null`. Clicking "Lost access" on login or in the disable modal returns `ErrorCode.MissingBackupCodes` (`disable.ts:55`, `next-auth-options.ts:137`) and renders "No backup codes found. Please generate them in your settings." No settings screen can generate them: `setup.ts` is the only writer and it returns `TwoFactorAlreadyEnabled` (`setup.ts:42`) for anyone with 2FA on. The message sends locked-out users on a dead-end loop.
   Fix: either add a backfill/regenerate path for existing 2FA users, or reword the string to direct them to support (`"No backup codes are set up for this account. Contact support to regain access."`).
   (bugs)

4. **[P2][conf 85] `resetState()` leaves backup codes and their blob URL alive for the tab's lifetime — `apps/web/components/settings/EnableTwoFactorModal.tsx:71`**
   Failure: `resetState` clears `password`, `errorMessage`, and `step`, but not `backupCodes` or `backupCodesUrl`. `URL.revokeObjectURL` is only called at line 98 on the *next* successful setup, which for most users never happens. After the user clicks "Close", the plaintext codes stay in React state and the object URL stays fetchable by any script on the page (including a later XSS on an unrelated settings route) until a full navigation.
   Fix: clear both in `resetState` and revoke the URL there:
   ```ts
   const resetState = () => {
     setPassword("");
     setErrorMessage(null);
     setStep(SetupStep.ConfirmPassword);
     setBackupCodes([]);
     if (backupCodesUrl) URL.revokeObjectURL(backupCodesUrl);
     setBackupCodesUrl("");
   };
   ```
   (bugs)

5. **[P2][conf 95] New backup-code component is named `TwoFactor` — `apps/web/components/auth/BackupCode.tsx:7`**
   Failure: `export default function TwoFactor({ center = true })` is a leftover from copying `TwoFactor.tsx`. Both components are imported side by side in `login.tsx:32-33` and `DisableTwoFactorModal.tsx:8-9`, so React DevTools, error boundaries, and stack traces show two different `TwoFactor` components — real confusion when debugging the 2FA login path.
   Fix: rename to `export default function BackupCode({ center = true })`.
   (slop)

Checked: bugs, conventions (no CLAUDE.md/AGENTS.md present in the repo or in any changed directory), history, comments, slop.
Skipped: `apps/web/public/static/locales/**` (translation data — en keys were verified to exist), `packages/prisma/migrations/20230804153419_add_backup_codes/migration.sql` (matches the schema change), `packages/lib/test/builder.ts` (fixture field addition). Deterministic detectors were not run.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
