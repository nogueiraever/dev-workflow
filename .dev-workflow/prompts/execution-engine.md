# Execution Engine Prompt

You are executing Phase 4 of the autonomous feature workflow. Tasks have been generated. You must now execute them autonomously, updating tracking documents continuously.

## Context

Read:
- `tasks.md` — the task breakdown with dependencies and parallel flags
- `progress.md` — current execution state
- `plan.md` — the approved plan for reference
- `decisions.md` — past decisions for context

## The Execution Loop

Repeat until all tasks are `done`:

```
1. Read tasks.md → find next executable tasks
2. If parallel batch available → launch sub-agents (one per task)
   If single/sequential task → execute directly
3. After completion → update tasks.md, progress.md, decisions.md
4. If new work discovered → update plan/tasks first, then continue
5. If blocked → log blocker, skip to next available task
6. Loop
```

## Finding Next Executable Tasks

A task is executable when:
- Status is `todo`
- All tasks in its `Dependency IDs` have status `done`

From executable tasks:
- Multiple tasks marked `parallelizable: true` → parallel batch
- Single task or `parallelizable: false` → sequential

## Parallel Execution

For each task in a parallel batch, launch a sub-agent with:
- The task definition (ID, title, description, linked plan items, notes)
- The implementer agent role (from `.dev-workflow/agents/implementer.md`)
- Relevant file paths and code context
- Project conventions

Sub-agents do NOT receive: other tasks, chat history, tracking files.

Each sub-agent reports back: status (Complete/Blocked/Partial), files changed, issues.

## After Each Task

**Complete:** Update task status → `done`, increment completed counter, update progress.md
**Blocked:** Update task status → `blocked`, increment blocked counter, log blocker in notes, continue to next task
**Partial:** Keep `in_progress`, note progress in task notes, continue in next iteration

Log any implementation decisions in `decisions.md`.

## Handling Discovered Work

If execution reveals new required work:
1. Stop current execution batch
2. Update `plan.md` if scope changed
3. Add new tasks to `tasks.md` with proper dependencies
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
- All tasks in `tasks.md` marked `done` (or `blocked` with reasons)
- `progress.md` reflects all completed work
- `decisions.md` captures all implementation decisions
- Transition `progress.md` to `current_phase: verifying`
