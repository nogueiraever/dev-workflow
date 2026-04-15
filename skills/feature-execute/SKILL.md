---
name: feature-execute
description: "Manual entrypoint: execute tasks for a feature. Reads tasks.md and runs tasks autonomously with parallel/sequential execution. Requires tasks to exist. Updates tracking docs continuously. Does NOT run verification."
argument-hint: "<feature-name>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
---

# Feature Execute (Manual Entrypoint)

This runs only Phase 4 of the feature workflow: Execution.

## Process

### 1. Validate

`$ARGUMENTS` must contain a feature name. If empty, ask for one.

Check that `docs/features/<name>/` exists. If not, suggest `/feature new <name>`.

### 2. Verify Preconditions

Read `tasks.md`:
- Must have real tasks (not just template content)
- If no tasks exist, suggest `/feature-tasks <name>` first

Read `plan.md`:
- Must have `status: approved`
- If not approved, suggest `/feature-init <name>` first

### 3. Load State

Read `progress.md` to determine where execution left off:
- If `current_phase` is not `executing`, update it to `executing`
- Check `current_task` for any interrupted task
- Read task statuses to find completed vs remaining work

### 4. Run Phase 4: Execution

Follow the process in the feature skill's [phase-execution.md](../feature/references/phase-execution.md):
- Find next executable tasks (dependencies satisfied)
- Launch parallel sub-agents for independent tasks
- Execute sequential tasks directly
- Update tasks.md, progress.md, decisions.md after each task
- Handle discovered work by updating plan/tasks first

### 5. Stop

After all tasks are `done` (or all remaining are `blocked`), stop.

Do NOT proceed to verification. Instead, update `progress.md` and suggest:
- `/feature-verify <name>` to run verification
- `/feature resume <name>` to continue the full workflow (which includes verification)

## Rules

Follow [rules.md](../feature/references/rules.md) for all tracking and markdown updates.
The autonomous execution rules apply: continue until all tasks are done, stop only for the 4 valid reasons.
