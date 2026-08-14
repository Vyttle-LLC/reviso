# review-pipeline

## MODIFIED Requirements

### Requirement: Per-finding verification with a confidence gate

Stage 4 SHALL re-examine every LLM candidate against the code with an
independent agent, and that agent SHALL return **findings of fact only**:
whether the cited lines are part of the change under review, what guards,
callers, or tests bear on the claimed failure scenario, and whether that
scenario reproduces against the real code. It SHALL NOT return a
confidence score, SHALL NOT return a drop reason, and SHALL NOT withhold or
gate a candidate. Deterministic findings bypass this stage.

The confidence gate SHALL be applied once, by the orchestrator, after
verification evidence is in hand. The orchestrator SHALL apply the
false-positive exclusion list and score each candidate on **Reviso's
confidence rubric**, drop candidates scoring below 80, and say nothing
about a dropped candidate in the default report. Because the orchestrator
holds every candidate at once, it — and only it — SHALL judge the rubric's
comparative bands, which ask how a candidate ranks relative to the rest of
the change.

The rubric SHALL score realness and importance as distinct inputs combined
by a stated rule, so that a verified-real finding of moderate importance is
distinguishable from an uncertain finding of high importance rather than
colliding with it near the threshold.

The rubric SHALL place **verified contract and enforcement defects** above
the ship threshold on the strength of a demonstrated gap alone. A contract
or enforcement defect is code, a comment, a prompt, or a configuration that
claims a guarantee the implementation does not deliver — validation that
checks shape but not the asserted property, a cross-check that matches one
phrasing of many, an invariant enforced only by prose. Such a defect SHALL
NOT be required to read as critical to functionality in order to ship, and
SHALL NOT be scored as a nitpick on the grounds that it fires rarely; its
cost is that the guarantee is false whenever it is relied upon.

Reviso's rubric SHALL be documented as a fork of the reference recipe's,
with its divergences stated, so a reader can tell which bands are inherited
and which are Reviso's own.

The orchestrator SHALL record, per candidate, the score it assigned and the
reason for any drop, drawn from the closed set `exclusion-list`,
`pre-existing`, `rubric-score`, or `none` for a candidate that cleared the
gate. That record is what `--explain` reports; without the flag it is not
surfaced. The gate's threshold and its default silence about dropped
candidates SHALL be unchanged by this requirement.

The rubric and the false-positive exclusion list SHALL be inputs to the
orchestrator and SHALL NOT be required reading for any subagent, so no
stage can gate a candidate against a reference it failed to load.

#### Scenario: Low-confidence finding dropped

- **WHEN** the orchestrator scores a finding at 60
- **THEN** the finding does not appear in the report and no mention of it
  is made

#### Scenario: Known false-positive class dropped

- **WHEN** a finder flags a pre-existing issue on lines the change did not
  modify
- **THEN** the orchestrator scores it as a false positive per the exclusion
  list and it is gated out

#### Scenario: Verification returns evidence, not a verdict

- **WHEN** a Stage 4 agent examines a candidate it judges to be wrong
- **THEN** it returns what it found against the code — the guard that
  already handles the case, the caller that cannot reach it — and returns
  no score and no drop reason

#### Scenario: Comparative scoring uses the whole change

- **WHEN** the orchestrator scores a candidate against the rubric band that
  asks how important it is relative to the rest of the change
- **THEN** it judges with every candidate from every lens in hand, rather
  than delegating that comparison to an agent holding one candidate

#### Scenario: Verified enforcement gap clears the gate

- **WHEN** a candidate demonstrates that a script's stated guarantee —
  "matches at most once", "fails loudly" — is enforced only by prose, and
  verification confirms the gap against the code
- **THEN** it scores above the threshold and ships, rather than being
  scored down for firing rarely or for not reading as critical to
  functionality

#### Scenario: Realness and importance do not collide

- **WHEN** the orchestrator holds a certainly-real finding of moderate
  importance and an uncertain finding of high importance
- **THEN** the two are scored on distinct inputs and are distinguishable at
  the threshold, rather than resolving to the same middling number

#### Scenario: Drop record survives for diagnostics

- **WHEN** the orchestrator gates a candidate because it matches the
  false-positive exclusion list
- **THEN** it records the drop reason `exclusion-list` for `--explain`, and
  the default report still says nothing about the candidate

#### Scenario: References are not subagent inputs

- **WHEN** the pipeline runs in an environment where a subagent cannot read
  files at the plugin root
- **THEN** no candidate is gated against an unread rubric or exclusion
  list, because gating happens only in the orchestrator
