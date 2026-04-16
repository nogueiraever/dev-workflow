# Resume Story Prompt

You are resuming work on a story in a new chat session. The previous session's context is gone. You must reconstruct state entirely from the markdown files.

## Instructions

### Step 1: Resolve Story Path

Look up the story ID in `docs/progress.md`:
- Find the story row in the Stories table
- Read the `Path` column to get the directory path
- If the ID is not found, search for the story by title or suggest creating a new story

### Step 2: Load All Story Files

Read every file at the resolved path:
- `story.md` — current phase, task state, plan, and scope
- `acceptance-criteria.md` — verification criteria
- `decisions.md` — past decisions for context

### Step 3: Parse State

From `story.md` YAML frontmatter extract:
- `current_phase` — which phase to resume
- `current_task` — which task was last active
- `last_updated` — when work last happened
- `total_tasks`, `completed_tasks`, `blocked_tasks` — task progress

### Step 4: Announce Resume

Tell the user:
```
Resuming story: [id] — [title]
Current phase: [phase]
Progress: [completed_tasks/total_tasks tasks done] (if applicable)
Last updated: [timestamp]
Next action: [what happens next]
```

### Step 5: Dispatch to Correct Phase

| current_phase | Action |
|---------------|--------|
| `intake` | Continue gathering requirements |
| `planning` | Continue generating plan sections in story.md |
| `pending_approval` | Re-present plan, wait for approval |
| `revising` | Ask what changes are still needed |
| `task_generation` | Continue generating tasks |
| `executing` | See execution resume below |
| `verifying` | Re-run verification |
| `closeout` | Generate final summary |
| `complete` | Inform user story is done |

### Step 6: Execution Phase Resume (if executing)

1. Build dependency graph from Tasks section in `story.md`
2. Categorize tasks: `done` (skip), `in_progress` (interrupted), `blocked`, `todo`
3. Handle interrupted task:
   - Check git status for uncommitted changes
   - Read affected files to assess progress
   - If complete → mark done. If partial → continue. If not started → treat as todo.
4. Find next executable tasks (dependencies satisfied, status: todo)
5. Continue the execution loop

### Edge Cases

- **Story not in docs/progress.md:** Search by title or path; suggest starting a new story if not found
- **story.md corrupted:** Reconstruct from acceptance-criteria.md and decisions.md, log decision
- **All tasks done but still `executing`:** Transition to verifying
- **Plan not yet approved:** Re-present for approval

## Output

- State reconstructed from markdown files
- User informed of current state
- Work continues from correct phase
