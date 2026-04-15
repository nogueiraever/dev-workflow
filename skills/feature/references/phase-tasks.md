# Phase 3: Task Generation

**Status value:** `task_generation`
**Agent:** [task-breaker](agents/task-breaker.md)

## Objective

Convert the approved plan into concrete, executable tasks with dependencies mapped and parallelization flags set. This phase runs automatically after plan approval — no user interaction needed.

## Process

### 1. Read the Plan

Load `plan.md` (approved) and `acceptance-criteria.md`. Focus on:
- Implementation Strategy (the approach and phase breakdown)
- Affected Pages / Modules (the specific files and areas)
- Scope items (each must map to at least one task)

### 2. Break Down Tasks

For each implementation phase in the plan, create tasks following these rules:

**Granularity:** Each task should touch 1-3 files and be completable in a focused session. If a task description says "and also..." it's probably two tasks.

**Completeness:** Map every scope item to at least one task. Map every acceptance criterion to at least one task. If something in scope has no task, add one.

**Task fields** (all required):
- **ID:** Sequential (T1, T2, T3...)
- **Title:** Short, action-oriented ("Create download button component", "Add API endpoint for export")
- **Description:** What to do, where to do it, and how to verify it works
- **Status:** `todo` (all tasks start as todo)
- **Dependency IDs:** Which tasks must be `done` before this can start. `none` if independent.
- **Parallelizable:** `true` if this task touches different files/modules than all concurrent tasks. `false` if it modifies shared code or depends on runtime state from another task.
- **Linked Plan Items:** Which plan section(s) this implements
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

Update the execution order diagram at the top of `tasks.md` to show this visually.

### 5. Update Frontmatter

Set `tasks.md` frontmatter:
- `total_tasks: N` (count of all tasks)
- `completed: 0`
- `blocked: 0`

### 6. Transition

Update `progress.md`:
- Set `current_phase: executing`
- Set `current_task: null` (execution will set it to the first task)
- Log the phase transition
- Update `last_updated`

Proceed immediately to Phase 4 (Execution).

## Exit Criteria

- `tasks.md` has all tasks defined with complete fields
- Every scope item maps to at least one task
- Dependencies are valid (no cycles, all referenced IDs exist)
- Parallel groups are identified
- `progress.md` shows `current_phase: executing`
