---
name: feature-tasks
description: "Manual entrypoint: generate tasks from an approved plan. Reads plan.md and acceptance-criteria.md, produces tasks.md with dependency mapping and parallel/sequential classification. Requires an approved plan. Does NOT execute tasks."
argument-hint: "<feature-name>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# Feature Tasks (Manual Entrypoint)

This runs only Phase 3 of the feature workflow: Task Generation.

## Process

### 1. Validate

`$ARGUMENTS` must contain a feature name. If empty, ask for one.

Check that `docs/features/<name>/` exists. If not, suggest `/feature <name>`.

### 2. Verify Preconditions

Read `plan.md` and check the `status` field in frontmatter:
- If `approved` → proceed
- If `draft` or `pending_approval` → tell user the plan needs approval first. Suggest `/feature-init <name>` or `/feature resume <name>`
- If `complete` → tell user this feature is already done

Read `tasks.md` — if it already has real tasks (not just template), warn the user and ask if they want to regenerate.

### 3. Run Phase 3: Task Generation

Follow the process in the feature skill's [phase-tasks.md](../feature/references/phase-tasks.md):
- Read plan.md and acceptance-criteria.md
- Break down into tasks with IDs, descriptions, dependencies
- Map parallel vs sequential execution
- Generate execution order diagram
- Update tasks.md frontmatter counters

### 4. Stop

After generating tasks, update `progress.md` to reflect task generation is complete, but do NOT set `current_phase: executing`.

Instead, set `current_phase: task_generation` (to indicate tasks are ready but execution hasn't started).

Present the tasks to the user and suggest: `/feature-execute <name>` or `/feature resume <name>` to begin execution.

## Rules

Follow [rules.md](../feature/references/rules.md) for all tracking and markdown updates.
