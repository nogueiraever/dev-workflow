# Task Generation Prompt

You are executing Phase 3 of the autonomous story workflow. The plan has been approved. You must now break it into executable tasks.

## Context

Read:
- `story.md` — the approved plan (status: approved) and the Tasks section where tasks will be written
- `acceptance-criteria.md` — the verification criteria

## Instructions

### Step 1: Analyze the Plan

Identify:
- Each implementation phase from the strategy
- Each affected file/module
- Each acceptance criterion that needs implementing
- The natural order of work (data models → APIs → UI, etc.)

### Step 2: Create Tasks

Tasks are written as `### T{N}:` headings inside the `## Tasks` section of `story.md`.

For each unit of work, define a task with ALL fields:

| Field | Description |
|-------|-------------|
| **Status** | `todo` (all start here) |
| **Dependencies** | Which task IDs must be `done` first, or `none` |
| **Parallelizable** | `true` only when touching independent code paths |
| **Description** | What to do, where to do it, how to verify |
| **Linked Criteria** | Which acceptance criteria IDs this implements (e.g., AC1, V2) |
| **Notes** | Existing code to reference, gotchas, patterns |

Example task format in `story.md`:

```markdown
### T1: Create data model for widget configuration
- **Status:** todo
- **Dependencies:** none
- **Parallelizable:** true
- **Description:** Create the WidgetConfig entity in the Domain layer...
- **Linked Criteria:** AC1, V1
- **Notes:** Follow existing entity patterns in Domain/Entities/
```

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

Write the execution order diagram in the `### Execution Order` sub-section of the Tasks section in `story.md`.

### Step 5: Update Tracking

Update `story.md` frontmatter: `total_tasks: N`, `completed_tasks: 0`, `blocked_tasks: 0`, `current_phase: executing`
Log the phase transition in the Phase History table.
Update `docs/progress.md` — set the story's Phase column to `executing`.

Proceed immediately to execution.

## Output

- Completed Tasks section in `story.md` with all tasks, dependencies, and execution diagram
- Updated `story.md` frontmatter showing transition to execution phase
- Updated `docs/progress.md` with current phase
