## Reviso review — HEAD (detached) vs 47e5bd23 (merge-base 15e1aa8855, 12 commits, 14 files)

Found 6 issues:

1. **[P1][conf 90] Delete and Pause are unreachable in the new Grafana rule list — menu items still gated on `rulerRule`** — `public/app/features/alerting/unified/components/rule-viewer/AlertRuleMenu.tsx:82`
   Failure: `GrafanaRuleListItem` renders `<RuleActionsButtons promRule={rule} …>` with no `rulerRule` (`GrafanaRuleListItem.tsx:47`), so `AlertRuleMenu` receives `rulerRule === undefined`. The new `grafanaPauseAbility` / `grafanaDeleteAbility` are computed (lines 82, 86) but the render guards `canPause && rulerRuleType.grafana.rule(rulerRule)` (line 123) and `canDelete && rulerRule` (line 165) are both false — a user with full permissions opens the More menu on any Grafana-managed rule in the list and gets no Pause and no Delete. The new test locks this in: `expect(menuItems.length).toBe(4)` at `GrafanaGroupLoader.test.tsx:869` asserts only silence/copy-link/duplicate/export.
   Fix: Drive the delete item off `canDelete` alone (`handleDelete` in `RuleActionsButtons.V2.tsx:99` already only uses `identifier`), and add a prom-rule path for `MenuItemPauseRule` (it currently requires `RulerGrafanaRuleDTO`). Then update the test to expect 6 items. If pause/delete are deliberately out of scope, drop the dead `grafanaPauseAbility`/`grafanaDeleteAbility` wiring and say so.
   (bugs)

2. **[P1][conf 85] Federated-rule-group guard silently removed from `useAllAlertRuleAbilities`** — `public/app/features/alerting/unified/hooks/useAbilities.ts:245`
   Failure: `useAllAlertRuleAbilities` was folded into `useAllRulerRuleAbilities`, which hardcodes `isFederated = false`. For a Mimir federated rule group, `useAlertRuleAbility(rule, Update)` now returns supported, so `RuleActionsButtons.tsx:57` renders an Edit button in the v1 rules table where it was previously suppressed. `ExistingRuleEditor.tsx:103` only renders a warning banner, so the user reaches a live edit form for a group the app treats as immutable. The comment two lines below (`useAbilities.ts:249`) still claims "if a rule is either provisioned, federated or provided by a plugin rule, we don't allow it to be removed or edited".
   Fix: Thread the ruler group (or a `isFederated` flag) into `useAllRulerRuleAbilities` and restore the check, rather than leaving a `TODO` that regresses an invariant established in #78231 (`7dbbdc16a3`).
   (history)

3. **[P1][conf 85] Missing React `key` on `GrafanaRuleListItem` in the filter view** — `public/app/features/alerting/unified/rule-list/FilterView.tsx:157`
   Failure: `key` is destructured at line 152 and passed to the `datasource` and `default` branches (lines 165, 169) but dropped from the `grafana` branch. `FilterViewResults` appends pages incrementally, so React reconciles Grafana rows by index: on each `loadResultPage` the existing rows are re-keyed, causing incorrect DOM/state reuse (open More menus, silence drawers) plus a console warning.
   Fix: `<GrafanaRuleListItem key={key} rule={rule} … />`.
   (bugs)

4. **[P2][conf 85] Grafana-managed recording rules lose the Export action in the list view** — `public/app/features/alerting/unified/hooks/useAbilities.ts:324`
   Failure: `useAllGrafanaPromRuleAbilities` sets `ModifyExport: [isAlertingRule, exportAllowed]` where `isAlertingRule = prometheusRuleType.grafana.alertingRule(rule)`. The ruler equivalent it replaces used `rulerRuleType.grafana.rule` (line 268), which covers recording rules too. In the list view only the prom path exists, so a Grafana recording rule's More menu no longer offers Export (`AlertRuleMenu.tsx:150`). The comment at line 301 — "All GrafanaPromRuleDTO rules are Grafana-managed by definition" — describes the old, wider variable, not the narrowed one below it.
   Fix: Use `prometheusRuleType.grafana.rule(rule)` for `ModifyExport` (and `Pause`, which supports GMA recording rules), keeping `alertingRule` only where alerting semantics are actually required (Silence).
   (comments)

5. **[P2][conf 85] `returnTo` dropped from the Grafana rule view link** — `public/app/features/alerting/unified/rule-list/GrafanaRuleListItem.tsx:41`
   Failure: The deleted `GrafanaRuleLoader.GrafanaRuleListItem` built the href as `createRelativeUrl(\`/alerting/grafana/${uid}/view\`, { returnTo })`; the replacement omits it. `RuleViewer.tsx:96` falls back to `/alerting/list`, so a user who opens a rule from a filtered/searched list and navigates back loses their filters. The sibling `DataSourceRuleListItem.tsx:36-42` still passes `returnTo`, so the two rule types now behave differently in the same list.
   Fix: `const returnTo = createReturnTo();` and `createRelativeUrl(\`/alerting/grafana/${uid}/view\`, { returnTo })`.
   (history)

6. **[P2][conf 80] Unused mock and duplicated explanatory comments in the reworked tests** — `public/app/features/alerting/unified/components/rules/RulesTable.test.tsx:26`
   Failure: `RulesTable` renders the v1 `RuleActionsButtons`, which uses `useAlertRuleAbility`, and `AlertRuleMenu`, which uses the plural hooks — nothing under test calls `useGrafanaPromRuleAbility`, yet it is mocked at line 26 and stubbed at line 65, and re-stubbed at line 89. The identical four-line comment "// Cloud rules only need useRulerRuleAbilities mock (useGrafanaPromRuleAbilities gets skipToken)" is pasted four times (lines 213, 235, 255, 275), and `useAbilities.ts:289` carries a stray `// duplicate` marker. The next reader has to re-derive which mocks actually matter.
   Fix: Delete the `useGrafanaPromRuleAbility` mock and its two stubs, state the cloud-rule rationale once in the `describe` block, and remove the `// duplicate` marker.
   (slop)

Checked: bugs, conventions, history, comments, slop. No `CLAUDE.md`/`AGENTS.md` exists at the repo root or under `public/app/features/alerting/`, so the conventions lens fell back to `eslint.config.js` and neighbouring-file idiom.
Skipped: `public/locales/en-US/grafana.json` (generated translations). The deterministic detector suite did not run — the `run.sh` invocation was not approved, so no `deterministic` findings are included.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
