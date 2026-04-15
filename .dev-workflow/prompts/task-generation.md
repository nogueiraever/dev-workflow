# Task Generation Prompt

You are executing Phase 3 of the autonomous feature workflow. The plan has been approved. You must now break it into executable tasks.

## Context

Read:
- `plan.md` — the approved plan (status: approved)
- `acceptance-criteria.md` — the verification criteria

## Instructions

### Step 1: Analyze the Plan

Identify:
- Each implementation phase from the strategy
- Each affected file/module
- Each acceptance criterion that needs implementing
- The natural order of work (data models → APIs → UI, etc.)

### Step 2: Create Tasks

For each unit of work, define a task with ALL fields:

| Field | Description |
|-------|-------------|
| **ID** | Sequential: T1, T2, T3... |
| **Title** | Short, action-oriented verb phrase |
| **Description** | What to do, where to do it, how to verify |
| **Status** | `todo` (all start here) |
| **Dependency IDs** | Which task IDs must be `done` first, or `none` |
| **Parallelizable** | `true` only when touching independent code paths |
| **Linked Plan Items** | Which plan section(s) this implements |
| **Notes** | Existing code to reference, gotchas, patterns |

### Step 3: Map Dependencies

- Backend tasks before frontend tasks that consume them
- Data model tasks before CRUD tasks
- Setup/config tasks before implementation tasks
- Component tasks before integration tasks

Validate: no circular dependencies. Every task reachable from a root task.

### Step 4: Build Execution Order

Group tasks into waves:
```
Wave 1: [T1, T2]     ← no dependencies, parallel
Wave 2: [T3, T4]     ← depend on wave 1, parallel with each other
Wave 3: [T5]          ← depends on wave 2, sequential
```

Write the execution order diagram at the top of `tasks.md`.

### Step 5: Update Tracking

Update `tasks.md` frontmatter: `total_tasks: N`, `completed: 0`, `blocked: 0`
Update `progress.md`: `current_phase: executing`, log transition

Proceed immediately to execution.

## Output

- Completed `tasks.md` with all tasks, dependencies, and execution diagram
- Updated `progress.md` showing transition to execution phase
