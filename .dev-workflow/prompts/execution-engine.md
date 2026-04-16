# Execution Engine Prompt

You are executing Phase 4 of the autonomous story workflow. Tasks have been generated. You must now execute them autonomously, updating tracking documents continuously.

## Context

Read:
- `story.md` — the task breakdown (Tasks section) with dependencies and parallel flags, the approved plan sections for reference, and current execution state (frontmatter)
- `decisions.md` — past decisions for context

## The Execution Loop

Repeat until all tasks are `done`:

```
1. Read story.md Tasks section → find next executable tasks
2. If parallel batch available → launch sub-agents (one per task)
   If single/sequential task → execute directly
3. After completion → update story.md (task status, frontmatter counters), decisions.md
4. After meaningful batches → update docs/progress.md Phase column for this story
5. If new work discovered → update plan/tasks in story.md first, then continue
6. If blocked → log blocker, skip to next available task
7. Loop
```

## Finding Next Executable Tasks

A task is executable when:
- Status is `todo`
- All tasks in its `Dependencies` have status `done`

From executable tasks:
- Multiple tasks marked `parallelizable: true` → parallel batch
- Single task or `parallelizable: false` → sequential

## Parallel Execution

For each task in a parallel batch, launch a sub-agent with:
- The task definition (ID, title, description, linked criteria, notes)
- The implementer agent role (from `.dev-workflow/agents/implementer.md`)
- Relevant file paths and code context
- Project conventions

Sub-agents do NOT receive: other tasks, chat history, tracking files.

Each sub-agent reports back: status (Complete/Blocked/Partial), files changed, issues.

## After Each Task

**Complete:** Update task status → `done` in `story.md`, recount frontmatter counters (`completed_tasks`, `blocked_tasks`), update `current_task`
**Blocked:** Update task status → `blocked` in `story.md`, recount frontmatter counters, log blocker in task notes, continue to next task
**Partial:** Keep `in_progress`, note progress in task notes, continue in next iteration

Log any implementation decisions in `decisions.md`.

After meaningful batches (one task or one parallel group), update `docs/progress.md` Phase column to reflect current progress.

## Handling Discovered Work

If execution reveals new required work:
1. Stop current execution batch
2. Update plan sections in `story.md` if scope changed
3. Add new tasks to the Tasks section of `story.md` with proper dependencies
4. Update execution order diagram
5. Log discovery in `decisions.md`
6. Resume loop

## Stopping Conditions

Stop only for:
- Unresolved ambiguity changing user-visible behavior → ask user
- Missing file access or external resource → report and wait
- Same error 3+ times → report with diagnostics
- Conflict with approved plan → report to user

Everything else: make a decision, log it, continue.

## Output

After all tasks are done:
- All tasks in `story.md` Tasks section marked `done` (or `blocked` with reasons)
- `story.md` frontmatter reflects all completed work
- `decisions.md` captures all implementation decisions
- Transition `story.md` frontmatter to `current_phase: verifying`
- Update `docs/progress.md` Phase column to `verifying`
