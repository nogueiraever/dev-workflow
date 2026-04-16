# Phase 3: Task Generation

**Status value:** `task_generation`
**Agent:** [task-breaker](agents/task-breaker.md)

## Objective

Convert the approved plan into concrete, executable tasks with dependencies mapped and parallelization flags set. Tasks are written into the Tasks section of `story.md`. This phase runs automatically after plan approval — no user interaction needed.

## Process

### 1. Read the Plan

Load `story.md` (plan sections) and `acceptance-criteria.md`. Focus on:
- Implementation Strategy (the approach and phase breakdown)
- Affected Pages / Modules (the specific files and areas)
- Scope items (each must map to at least one task)

### 2. Break Down Tasks

For each implementation phase in the plan, create tasks following these rules:

**Granularity:** Each task should touch 1-3 files and be completable in a focused session. If a task description says "and also..." it's probably two tasks.

**Completeness:** Map every scope item to at least one task. Map every acceptance criterion to at least one task. If something in scope has no task, add one.

**Task format** (written as ### headings under the ## Tasks section in `story.md`):

```markdown
### T1: [Title]
- **Status:** todo
- **Dependencies:** none
- **Parallelizable:** true
- **Description:** [What to do, where to do it, and how to verify it works]
- **Linked Criteria:** [Which acceptance criteria this implements]
- **Notes:** [Any helpful context — existing code to reference, gotchas, patterns to follow]
```

**Task fields** (all required):
- **ID:** Sequential (T1, T2, T3...)
- **Title:** Short, action-oriented ("Create download button component", "Add API endpoint for export")
- **Status:** `todo` (all tasks start as todo)
- **Dependencies:** Which tasks must be `done` before this can start. `none` if independent.
- **Parallelizable:** `true` if this task touches different files/modules than all concurrent tasks. `false` if it modifies shared code or depends on runtime state from another task.
- **Description:** What to do, where to do it, and how to verify it works
- **Linked Criteria:** Which acceptance criteria this implements
- **Notes:** Any helpful context (existing code to reference, gotchas, patterns to follow)

### 3. Map Dependencies

Build the dependency graph:
- Backend tasks before frontend tasks that consume them
- Data model tasks before CRUD tasks
- Setup/config tasks before implementation tasks
- Component tasks before integration tasks

Verify: no circular dependencies. Every task is reachable from at least one task with no dependencies.

### 4. Identify Parallel Groups

Group tasks into execution waves:

```
Wave 1: [T1, T2]     ← no dependencies, can run in parallel
Wave 2: [T3, T4]     ← depend on wave 1, can run in parallel with each other
Wave 3: [T5]          ← depends on T3 and T4, must wait
```

Write the execution order diagram under `### Execution Order` within the Tasks section of `story.md`.

### 5. Update Frontmatter

Set `story.md` frontmatter:
- `total_tasks: N` (count of all tasks)
- `completed_tasks: 0`
- `blocked_tasks: 0`

### 6. Transition

Update `story.md` frontmatter:
- Set `current_phase: executing`
- Set `current_task: null` (execution will set it to the first task)
- Update `last_updated`

Log the phase transition in the Phase History section.

Update `docs/progress.md` Phase column for this story.

Proceed immediately to Phase 4 (Execution).

## Exit Criteria

- `story.md` Tasks section has all tasks defined with complete fields
- Every scope item maps to at least one task
- Dependencies are valid (no cycles, all referenced IDs exist)
- Parallel groups are identified in the Execution Order diagram
- `story.md` frontmatter shows `current_phase: executing` with accurate counters
- `docs/progress.md` reflects the phase transition
