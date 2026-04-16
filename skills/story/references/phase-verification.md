# Phase 5: Verification

**Status value:** `verifying`
**Agent:** [verifier](agents/verifier.md)

## Objective

Validate the implementation against acceptance criteria and plan. Identify gaps before declaring the story complete. If gaps are found, generate follow-up tasks and return to execution.

## Process

### 1. Load Context

Read all story files:
- `story.md` — plan sections for scope coverage, Tasks section to confirm all tasks are done
- `acceptance-criteria.md` — the criteria to verify against
- `decisions.md` — understand any deviations from original plan

### 2. Verify Task Completion

Check the Tasks section in `story.md`:
- Are all tasks marked `done`?
- Are any tasks still `in_progress` or `todo`? (should not happen — indicates incomplete execution)
- Are any tasks `blocked`? If so, can the blocker be resolved now?

If incomplete tasks exist, return to Phase 4 (Execution) to complete them.

### 3. Verify Acceptance Criteria

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

### 4. Run Automated Checks

If the project has automated tooling, run it:
- **Tests:** `pnpm test`, `npm test`, `dotnet test`, or equivalent
- **Type checking:** `pnpm tsc`, `npm run tsc`, or equivalent
- **Linting:** `pnpm lint`, `npm run lint`, or equivalent

Report results. Failing tests related to the story are blocking.

### 5. Check for Regressions

Look for obvious regressions:
- Did any existing tests break?
- Were any files modified that aren't related to the story?
- Are there any TODO/FIXME comments left in the new code?

### 6. Assess Gaps

Compile the verification results:

**If all criteria pass and no gaps found:**
- Update `story.md` frontmatter: `current_phase: closeout`, `last_updated: <now>`
- Log the transition in the Phase History section
- Update `docs/progress.md` Phase column
- Proceed to Phase 6 (Closeout)

**If gaps found:**
- For each gap, create a follow-up task in the Tasks section of `story.md`:
  - ID continues from last task (T{N+1}, T{N+2}...)
  - Description clearly states what's missing and how to fix it
  - Dependencies reference any tasks whose work needs extending
  - Linked to the specific failed acceptance criteria
- Update `story.md` frontmatter: `total_tasks` increases, `current_phase: executing`, `last_updated: <now>`
- Log the gaps found in `decisions.md`
- Update `docs/progress.md` Phase column
- Return to Phase 4 (Execution) to address gaps

### 7. Update Acceptance Criteria

Update `acceptance-criteria.md`:
- Each criterion now has `passed`, `failed`, or `skipped` status
- Update frontmatter: `passed` count
- The Success Conditions checklist reflects the true state

## Exit Criteria

- Every acceptance criterion has been evaluated (no `pending` statuses remain)
- All automated checks pass (or failures are documented and have follow-up tasks)
- No blocking gaps remain
- `story.md` frontmatter shows `current_phase: closeout`
- `docs/progress.md` reflects the phase transition
