# Resume Algorithm

This document defines how to resume a story workflow in a new chat session.

## Entry Point

When `/story resume <id>` is invoked (or `/story <id>` matches an existing story, or `/story list` selects an in-progress story):

## Step 1: Resolve Story Path

1. Read `docs/progress.md`
2. Find the row where the ID column matches the given `<id>` (case-insensitive)
3. Extract the Path column value — this is the story directory
4. If not found, tell the user and suggest `/story create --id <id>`

## Step 2: Load All Story Files

Read every file in the resolved story path:
- `story.md` — canonical state: frontmatter has current phase, task counters; body has plan, tasks, status
- `acceptance-criteria.md` — verification criteria
- `decisions.md` — past decisions for context

## Step 3: Parse State

Extract from `story.md` YAML frontmatter:
- `current_phase` — which phase to resume
- `current_task` — which task was last active (if in execution)
- `last_updated` — when work last happened
- `total_tasks`, `completed_tasks`, `blocked_tasks` — progress counters

## Step 4: Announce Resume

After determining the state, tell the user:

```
Resuming story: [id] — [title]
Current phase: [phase]
Progress: [X/Y tasks done] (if in execution)
Last updated: [timestamp]
Next action: [what will happen next]
```

## Step 5: Dispatch to Correct Phase

| `current_phase` | Action |
|-----------------|--------|
| `intake` | Re-read story.md notes. Continue gathering requirements — ask the user what they'd like to build or clarify. |
| `planning` | Continue filling story.md plan sections that are still placeholder/template text. |
| `pending_approval` | Present the plan to the user again. Summarize what the plan covers. Wait for approval or change requests. |
| `revising` | Read story.md. Ask the user what changes are still needed, or if previous feedback has been addressed. |
| `task_generation` | Check if story.md Tasks section has real tasks or only template. If partial, continue generating. If empty, start from the plan sections. |
| `executing` | **See detailed execution resume below.** |
| `verifying` | Re-run verification against acceptance-criteria.md. Check each criterion. |
| `closeout` | Generate the final summary if not yet written. |
| `complete` | Inform the user the story is complete. Ask if they want to reopen or start follow-up work. |

Then proceed with that action.

## Execution Phase Resume (Detailed)

When resuming `current_phase: executing`:

1. **Build the dependency graph** from the Tasks section in `story.md`. Parse every task's `Dependencies` field.

2. **Categorize tasks by status:**
   - `done` — already completed, skip
   - `in_progress` — was interrupted mid-execution
   - `blocked` — has unresolved blockers
   - `todo` — not yet started

3. **Handle `in_progress` task (if any):**
   - Check git status for uncommitted changes related to this task
   - Read the files the task was supposed to modify
   - Assess: is the work complete, partial, or not started?
   - If complete: mark `done`, update story.md task status and frontmatter counters
   - If partial: continue from where it left off
   - If not started: treat as `todo`

4. **Find next executable tasks:**
   - From all `todo` tasks, find those whose dependencies are all `done`
   - Among those, identify which are `parallelizable: true`
   - Group parallel-safe tasks into a batch
   - Sequential tasks execute one at a time

5. **Continue the execution loop** as defined in [phase-execution.md](phase-execution.md).

## Edge Cases

- **Story not found in docs/progress.md:** Tell the user. Suggest `/story create --id <id>` instead.
- **story.md is corrupted/missing frontmatter:** Read acceptance-criteria.md and decisions.md to infer state. Reconstruct story.md frontmatter. Log decision.
- **All tasks done but phase is still `executing`:** Transition to `verifying`.
- **Story was never approved:** If story.md current_phase is `intake` or `planning`, restart from the appropriate phase.
