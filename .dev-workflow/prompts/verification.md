# Verification Prompt

You are executing Phase 5 of the autonomous story workflow. All tasks are done. You must now verify the implementation against acceptance criteria.

## Context

Read:
- `acceptance-criteria.md` — the criteria to verify against
- `story.md` — confirm all tasks are done (Tasks section) and verify scope coverage (plan sections)
- `decisions.md` — understand any deviations

## Instructions

### Step 1: Verify Task Completion

Check `story.md` Tasks section:
- Are all tasks `done`?
- Any still `in_progress` or `todo`? → return to execution
- Any `blocked`? → can the blocker be resolved now?

### Step 2: Verify Each Acceptance Criterion

Walk through `acceptance-criteria.md` section by section:

For each criterion:
1. Read the criterion
2. Find the corresponding implementation in the codebase
3. Verify it works as specified:
   - Code behavior: read and trace the logic
   - UI criteria: check component renders correctly
   - API criteria: verify endpoint exists with correct signature
   - Validation criteria: check validation logic exists
4. Update status: `passed` | `failed` | `skipped`
5. If `failed`: note what's wrong

### Step 3: Run Automated Checks

If the project has automated tooling:
- Tests: `pnpm test`, `npm test`, `dotnet test`
- Type checking: `pnpm tsc`, `npm run tsc`
- Linting: `pnpm lint`, `npm run lint`

Report results. Failing tests related to the story are blocking.

### Step 4: Check for Regressions

- Did any existing tests break?
- Were unrelated files modified?
- Any TODO/FIXME comments left in new code?

### Step 5: Assess and Route

**All criteria pass, no gaps:**
- Update `story.md` frontmatter: `current_phase: closeout`
- Update `docs/progress.md` Phase column to `closeout`
- Proceed to closeout

**Gaps found:**
- Generate follow-up tasks in `story.md` Tasks section for each gap
- Link to failed acceptance criteria
- Update `story.md` frontmatter: `current_phase: executing`
- Update `docs/progress.md` Phase column to `executing`
- Return to execution phase

## Output

- Each criterion in `acceptance-criteria.md` has a status (no `pending` remaining)
- `story.md` frontmatter updated with verification results
- Follow-up tasks created if gaps found
- Clear routing: closeout or back to execution
