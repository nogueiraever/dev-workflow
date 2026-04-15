---
name: feature-verify
description: "Manual entrypoint: verify a feature implementation against acceptance criteria. Checks each criterion, runs automated tests, identifies gaps. If gaps found, generates follow-up tasks but does NOT execute them."
argument-hint: "<feature-name>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# Feature Verify (Manual Entrypoint)

This runs only Phase 5 of the feature workflow: Verification.

## Process

### 1. Validate

`$ARGUMENTS` must contain a feature name. If empty, ask for one.

Check that `docs/features/<name>/` exists. If not, suggest `/feature <name>`.

### 2. Verify Preconditions

Read `tasks.md`:
- Check that tasks exist and most are `done`
- If many tasks are still `todo`, warn the user — verification is premature

Read `acceptance-criteria.md`:
- Must have real criteria (not just template)
- If no criteria exist, warn the user

### 3. Run Phase 5: Verification

Follow the process in the feature skill's [phase-verification.md](../feature/references/phase-verification.md):
- Verify task completion (all tasks done?)
- Walk through each acceptance criterion and verify
- Run automated checks (tests, type checking, linting)
- Check for regressions
- Update criterion statuses in acceptance-criteria.md

### 4. Report Results

Present a verification report:
```
## Verification Report: [feature-name]

### Acceptance Criteria
- AC1: [criterion] — passed/failed
- AC2: [criterion] — passed/failed

### Automated Checks
- Tests: pass/fail
- Type check: pass/fail
- Lint: pass/fail

### Gaps Found
- [gap description] (if any)

### Verdict
All pass → Ready for closeout
Gaps found → Follow-up tasks generated in tasks.md
```

### 5. Handle Gaps

If gaps are found:
- Generate follow-up tasks in `tasks.md`
- Do NOT execute them
- Suggest: `/feature-execute <name>` to fix gaps, then re-verify

If all pass:
- Update `progress.md`: `current_phase: closeout` (or leave as `verifying` if user wants to manually close out)
- Suggest: `/feature resume <name>` to run closeout

## Rules

Follow [rules.md](../feature/references/rules.md) for all tracking and markdown updates.
