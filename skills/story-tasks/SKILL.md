---
name: story-tasks
description: "Manual entrypoint: generate tasks from an approved story plan. Reads story.md plan sections and acceptance-criteria.md, produces tasks in the Tasks section of story.md with dependency mapping and parallel/sequential classification. Requires an approved plan. Does NOT execute tasks."
argument-hint: "<id>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# Story Tasks (Manual Entrypoint)

This runs only Phase 3 of the story workflow: Task Generation.

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

Check `current_phase` in `story.md` frontmatter:

- If `pending_approval` with an approved plan (user approved but phase wasn't advanced yet) OR `task_generation` → proceed
- If `intake` or `planning` or `revising` → tell user the plan needs approval first. Suggest `/story-init <id>` or `/story resume <id>`
- If `executing`, `verifying`, `closeout`, or `complete` → tell user this story already has tasks. If they want to regenerate, they must confirm explicitly.

Check the Tasks section of `story.md`:
- If it already has real tasks (not just template placeholders), warn the user and ask if they want to regenerate
- If regenerating, preserve existing task statuses for reference in decisions.md

### 3. Run Phase 3: Task Generation

Follow the process in the story skill's [phase-tasks.md](../story/references/phase-tasks.md):

#### Read the Plan

Load the plan sections from `story.md` (Summary, Scope, Implementation Strategy, Affected Pages/Modules) and `acceptance-criteria.md`. Focus on:
- Implementation Strategy (the approach and phase breakdown)
- Affected Pages / Modules (the specific files and areas)
- Scope items (each must map to at least one task)

#### Break Down Tasks

For each implementation phase in the plan, create tasks:

**Granularity:** Each task should touch 1-3 files and be completable in a focused session. If a task description says "and also..." it's probably two tasks.

**Completeness:** Map every scope item to at least one task. Map every acceptance criterion to at least one task.

**Task format in story.md Tasks section:**

```markdown
## Tasks

### Execution Order
[Visual dependency diagram showing waves]

### T1: [Title]
- **Status:** todo
- **Dependencies:** none
- **Parallelizable:** true | false
- **Description:** [What to do, where to do it, how to verify]
- **Linked Criteria:** [Which acceptance criteria this implements]
- **Notes:** [Context, gotchas, patterns to follow]

### T2: [Title]
...
```

#### Map Dependencies

Build the dependency graph:
- Backend tasks before frontend tasks that consume them
- Data model tasks before CRUD tasks
- Setup/config tasks before implementation tasks
- Component tasks before integration tasks

Verify: no circular dependencies. Every task is reachable from at least one task with no dependencies.

#### Identify Parallel Groups

Group tasks into execution waves:
```
Wave 1: [T1, T2]     <- no dependencies, can run in parallel
Wave 2: [T3, T4]     <- depend on wave 1, can run in parallel with each other
Wave 3: [T5]          <- depends on T3 and T4, must wait
```

Write the execution order diagram in the Tasks section.

#### Update Frontmatter

Update `story.md` frontmatter:
- `total_tasks: N` (count of all tasks)
- `completed_tasks: 0`
- `blocked_tasks: 0`
- `current_phase: task_generation`
- `last_updated: <ISO-TIMESTAMP>`

### 4. Stop

After generating tasks:
- Log the phase transition in the Phase History section of `story.md`
- Update `docs/progress.md` Phase column to `task_generation`
- Do NOT set `current_phase: executing` — tasks are ready but execution hasn't started

Present the tasks to the user with a summary:
```
## Tasks Generated for [story-id]

Total tasks: N
Parallel waves: M
Estimated execution waves:
  Wave 1: T1, T2 (parallel)
  Wave 2: T3 (sequential)
  ...

Full task list: [path-to-story.md]

Next steps:
- /story-execute <id>  — execute tasks
- /story resume <id>   — resume full workflow (includes execution)
```

## Error Handling

- **Story not found in progress.md:** Suggest `/story create --id <id>`
- **Plan not approved:** Suggest `/story-init <id>` to complete planning
- **Tasks already exist:** Warn and ask for confirmation before regenerating
- **Empty plan sections:** Cannot generate tasks from an incomplete plan. Suggest `/story-init <id>` to complete planning first.

## Rules

Follow [rules.md](../story/references/rules.md) for all tracking and markdown updates.

All state transitions must:
1. Update `story.md` frontmatter (`current_phase`, `last_updated`)
2. Log the transition in the Phase History section of `story.md`
3. Update `docs/progress.md` Phase column
