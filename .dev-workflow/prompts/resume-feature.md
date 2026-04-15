# Resume Feature Prompt

You are resuming work on a feature in a new chat session. The previous session's context is gone. You must reconstruct state entirely from the markdown files.

## Instructions

### Step 1: Load All Feature Files

Read every file in `docs/features/<feature-name>/`:
- `progress.md` — current phase and task state
- `plan.md` — the plan and its approval status
- `tasks.md` — task breakdown and statuses
- `acceptance-criteria.md` — verification criteria
- `decisions.md` — past decisions for context

### Step 2: Parse State

From `progress.md` YAML frontmatter extract:
- `current_phase` — which phase to resume
- `current_task` — which task was last active
- `last_updated` — when work last happened

### Step 3: Announce Resume

Tell the user:
```
Resuming feature: [name]
Current phase: [phase]
Progress: [X/Y tasks done] (if applicable)
Last updated: [timestamp]
Next action: [what happens next]
```

### Step 4: Dispatch to Correct Phase

| current_phase | Action |
|---------------|--------|
| `intake` | Continue gathering requirements |
| `planning` | Continue generating plan.md |
| `pending_approval` | Re-present plan, wait for approval |
| `revising` | Ask what changes are still needed |
| `task_generation` | Continue generating tasks |
| `executing` | See execution resume below |
| `verifying` | Re-run verification |
| `closeout` | Generate final summary |
| `complete` | Inform user feature is done |

### Step 5: Execution Phase Resume (if executing)

1. Build dependency graph from tasks.md
2. Categorize tasks: `done` (skip), `in_progress` (interrupted), `blocked`, `todo`
3. Handle interrupted task:
   - Check git status for uncommitted changes
   - Read affected files to assess progress
   - If complete → mark done. If partial → continue. If not started → treat as todo.
4. Find next executable tasks (dependencies satisfied, status: todo)
5. Continue the execution loop

### Edge Cases

- **Directory doesn't exist:** Suggest starting a new feature
- **progress.md corrupted:** Reconstruct from tasks.md and plan.md, log decision
- **All tasks done but still `executing`:** Transition to verifying
- **Plan not yet approved:** Re-present for approval

## Output

- State reconstructed from markdown files
- User informed of current state
- Work continues from correct phase
