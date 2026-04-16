---
name: story-verify
description: "Manual entrypoint: verify a story implementation against acceptance criteria. Resolves story by ID, checks each criterion, runs automated tests, identifies gaps. If gaps found, generates follow-up tasks in story.md but does NOT execute them."
argument-hint: "<id>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# Story Verify (Manual Entrypoint)

This runs only Phase 5 of the story workflow: Verification.

## Process

### 1. Resolve Story

`$ARGUMENTS` must contain a story ID. If empty, ask for one.

**Resolve story path from `docs/progress.md`:**
1. Read `docs/progress.md`
2. Search the ID column for a row matching the provided ID (case-insensitive)
3. Extract the Path column value
4. If not found, tell the user the story doesn't exist and suggest `/story create --id <id>`

Read `story.md` from the resolved path.

### 2. Verify Preconditions

**Check Tasks section of `story.md`:**
- Tasks must exist and most should be `done`
- If many tasks are still `todo`, warn the user — verification is premature
- If tasks are `in_progress`, suggest completing execution first: `/story-execute <id>`

**Check `acceptance-criteria.md`:**
- Must exist in the story directory
- Must have real criteria (not just template placeholders)
- If no criteria exist, warn the user and suggest `/story-init <id>` to generate them

**Check `story.md` frontmatter `current_phase`:**
- If `executing` or `verifying` → proceed (normal flow)
- If `intake`, `planning`, `pending_approval`, `revising`, `task_generation` → too early for verification. Suggest the appropriate next step.
- If `complete` → story is already done. Ask if re-verification is intended.

### 3. Run Phase 5: Verification

Update `story.md` frontmatter: `current_phase: verifying`, `last_updated: <ISO-TIMESTAMP>`
Update `docs/progress.md` Phase column to `verifying`.
Log the transition in Phase History.

Follow the process in the story skill's [phase-verification.md](../story/references/phase-verification.md):

#### Verify Task Completion

Check the Tasks section of `story.md`:
- Are all tasks marked `done`?
- Are any tasks still `in_progress` or `todo`? (should not happen — indicates incomplete execution)
- Are any tasks `blocked`? If so, can the blocker be resolved now?

If incomplete tasks exist that should have been done, note them as gaps.

#### Verify Acceptance Criteria

Walk through `acceptance-criteria.md` section by section:

**For each criterion:**
1. Read the criterion
2. Find the corresponding implementation in the codebase
3. Verify it works as specified:
   - For code behavior: read the code and trace the logic
   - For UI criteria: check the component renders correctly
   - For API criteria: verify the endpoint exists with correct signature
   - For validation criteria: check validation logic exists
4. Update the criterion status: `passed` | `failed` | `skipped`
5. If `failed`: note what's wrong and what needs fixing

#### Run Automated Checks

If the project has automated tooling, run it:
- **Tests:** `pnpm test`, `npm test`, `dotnet test`, or equivalent
- **Type checking:** `pnpm tsc`, `npm run tsc`, or equivalent
- **Linting:** `pnpm lint`, `npm run lint`, or equivalent

Report results. Failing tests related to the story are blocking.

#### Check for Regressions

Look for obvious regressions:
- Did any existing tests break?
- Were any files modified that aren't related to the story?
- Are there any TODO/FIXME comments left in the new code?

### 4. Report Results

Present a verification report:
```
## Verification Report: [story-id] - [title]

### Acceptance Criteria
- AC1: [criterion] -- passed/failed
- AC2: [criterion] -- passed/failed
...

### Automated Checks
- Tests: pass/fail (X passed, Y failed)
- Type check: pass/fail
- Lint: pass/fail

### Gaps Found
- [gap description] (if any)

### Verdict
All pass -> Ready for closeout
Gaps found -> Follow-up tasks generated in story.md
```

### 5. Handle Gaps

**If gaps are found:**
- Generate follow-up tasks in the Tasks section of `story.md`:
  - IDs continue from last task (T{N+1}, T{N+2}...)
  - Description clearly states what's missing and how to fix it
  - Dependencies reference any tasks whose work needs extending
  - Linked to the specific failed acceptance criteria
- Update `story.md` frontmatter:
  - `total_tasks` increases to include new tasks
  - `current_phase` stays as `verifying` (do NOT set to `executing`)
- Log the gaps found in `decisions.md`
- Do NOT execute the follow-up tasks
- Suggest: `/story-execute <id>` to fix gaps, then re-verify with `/story-verify <id>`

**If all pass:**
- Update `acceptance-criteria.md` with final statuses
- Update `story.md` frontmatter: `current_phase: verifying` (leave as-is, do not advance to closeout)
- Update `docs/progress.md` Phase column and Last Updated
- Suggest: `/story resume <id>` to run closeout

### 6. Update Acceptance Criteria

Update `acceptance-criteria.md`:
- Each criterion now has `passed`, `failed`, or `skipped` status
- Update any frontmatter counters (if applicable)
- The Success Conditions checklist reflects the true state

Update `docs/progress.md` Last Updated column.

## Error Handling

- **Story not found in progress.md:** Suggest `/story create --id <id>`
- **No tasks in story.md:** Suggest `/story-tasks <id>` to generate tasks first
- **No acceptance criteria:** Suggest `/story-init <id>` to complete planning
- **Most tasks still todo:** Warn that verification is premature. Suggest `/story-execute <id>` first
- **Verification loop detected** (gaps -> execute -> verify -> gaps, 3+ times): Stop and report to user. Something fundamental is wrong with the plan or implementation approach.

## Rules

Follow [rules.md](../story/references/rules.md) for all tracking and markdown updates.

All state transitions must:
1. Update `story.md` frontmatter (`current_phase`, `last_updated`)
2. Log the transition in the Phase History section of `story.md`
3. Update `docs/progress.md` Phase and Last Updated columns
