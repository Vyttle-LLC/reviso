# review-pipeline

## ADDED Requirements

### Requirement: Finder history access is bounded by the change under review

A finder that reads git history SHALL treat as inadmissible any evidence
reachable only through commits that are not ancestors of the change's head
— sibling branches, later commits on the same branch, and anything else
visible to `git log --all` but not to the change itself. A finding SHALL
NOT cite such a commit as evidence, and a finder that discovers one SHALL
proceed as though it were absent.

The change under review defines the world a reviewer can see. On a user's
real branch the constraint is inert, because there is no future to reach.
In evaluation it is load-bearing: every corpus case drawn from this
repository sits in an object store that also contains the commits which
later fixed the very issues under review, and a lens that reads them
reports a recall it did not earn.

#### Scenario: Future commits are inadmissible

- **WHEN** a history or prior-review finder encounters a commit that is
  not an ancestor of the change's head
- **THEN** it does not cite that commit as evidence, and any candidate
  resting solely on it is not returned

#### Scenario: Real-branch behaviour is unchanged

- **WHEN** a finder runs against a user's working branch, where no commit
  after the change's head exists
- **THEN** the bound excludes nothing and the lens behaves exactly as
  before

#### Scenario: Evaluation runs are not contaminated

- **WHEN** a corpus case is drawn from a repository whose object store
  contains the case's own future
- **THEN** the recorded candidate findings cite only evidence reachable
  from the case's head, so the measured recall reflects what the lens
  could see at review time
