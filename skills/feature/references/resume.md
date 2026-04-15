# Resume Algorithm

This document defines how to resume a feature workflow in a new chat session.

## Entry Point

When `/feature resume <name>` is invoked (or `/feature` selects an in-progress feature):

## Step 1: Load All Feature Files

Read every file in `docs/features/<name>/`:
- `progress.md` — current phase and task state
- `plan.md` — the approved plan
- `tasks.md` — task breakdown and statuses
- `acceptance-criteria.md` — verification criteria
- `decisions.md` — past decisions for context

## Step 2: Parse State

Extract from `progress.md` YAML frontmatter:
- `current_phase` — which phase to resume
- `current_task` — which task was last active (if in execution)
- `last_updated` — when work last happened

## Step 3: Dispatch to Correct Phase

| `current_phase` | Action |
|-----------------|--------|
| `intake` | Re-read plan.md notes. Continue gathering requirements — ask the user what they'd like to build or clarify. |
| `planning` | Continue generating plan.md sections that are still placeholder/template text. |
| `pending_approval` | Present the plan to the user again. Summarize what the plan covers. Wait for approval or change requests. |
| `revising` | Read plan.md. Ask the user what changes are still needed, or if previous feedback has been addressed. |
| `task_generation` | Check if tasks.md has real tasks or only template. If partial, continue generating. If empty, start from plan.md. |
| `executing` | **See detailed execution resume below.** |
| `verifying` | Re-run verification against acceptance-criteria.md. Check each criterion. |
| `closeout` | Generate the final summary if not yet written. |
| `complete` | Inform the user the feature is complete. Ask if they want to reopen or start follow-up work. |

## Step 4: Execution Phase Resume (Detailed)

When resuming `current_phase: executing`:

1. **Build the dependency graph** from tasks.md. Parse every task's `Dependency IDs` field.

2. **Categorize tasks by status:**
   - `done` — already completed, skip
   - `in_progress` — was interrupted mid-execution
   - `blocked` — has unresolved blockers
   - `todo` — not yet started

3. **Handle `in_progress` task (if any):**
   - Check git status for uncommitted changes related to this task
   - Read the files the task was supposed to modify
   - Assess: is the work complete, partial, or not started?
   - If complete: mark `done`, update tasks.md
   - If partial: continue from where it left off
   - If not started: treat as `todo`

4. **Find next executable tasks:**
   - From all `todo` tasks, find those whose dependencies are all `done`
   - Among those, identify which are `parallelizable: true`
   - Group parallel-safe tasks into a batch
   - Sequential tasks execute one at a time

5. **Continue the execution loop** as defined in [phase-execution.md](phase-execution.md).

## Step 5: Announce Resume

After determining the state, tell the user:

```
Resuming feature: [name]
Current phase: [phase]
Progress: [X/Y tasks done] (if in execution)
Last updated: [timestamp]
Next action: [what will happen next]
```

Then proceed with that action.

## Edge Cases

- **Feature directory doesn't exist:** Tell the user. Suggest `/feature new <name>` instead.
- **progress.md is corrupted/missing frontmatter:** Read tasks.md and plan.md to infer state. Reconstruct progress.md. Log decision.
- **All tasks done but phase is still `executing`:** Transition to `verifying`.
- **Feature was never approved:** If plan.md status is `draft` and progress says `intake` or `planning`, restart from the appropriate phase.
