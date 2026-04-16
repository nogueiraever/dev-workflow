---
name: story-execute
description: "Manual entrypoint: execute tasks for a story. Reads tasks from the Tasks section of story.md and runs them autonomously with parallel/sequential execution. Requires tasks to exist. Updates story.md and docs/progress.md continuously. Does NOT run verification."
argument-hint: "<id>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
---

# Story Execute (Manual Entrypoint)

This runs only Phase 4 of the story workflow: Execution.

## Process

### 1. Resolve Story

`$ARGUMENTS` must contain a story ID. If empty, ask for one.

**Resolve story path from `docs/progress.md`:**
1. Read `docs/progress.md`
2. Search the ID column for a row matching the provided ID (case-insensitive)
3. Extract the Path column value
4. If not found, tell the user the story doesn't exist and suggest `/story create --id <id>`

Read `story.md` from the resolved path.

### 2. Verify Preconditions

**Check Tasks section of `story.md`:**
- Must have real tasks (task entries with IDs like T1, T2, etc.)
- If no tasks exist, suggest `/story-tasks <id>` first

**Check `story.md` frontmatter:**
- `current_phase` should be `task_generation` or `executing` (resuming)
- If `intake`, `planning`, `pending_approval`, or `revising` → plan not ready. Suggest `/story-init <id>` first
- If `verifying` or `closeout` → this story is past execution. Suggest `/story-verify <id>` or `/story resume <id>`
- If `complete` → story is done. Tell the user.

### 3. Load State

Read `story.md` to determine where execution left off:
- If `current_phase` is not `executing`, update it to `executing`
- Check `current_task` for any interrupted task
- Parse all task entries from the Tasks section: extract ID, Status, Dependencies, Parallelizable flag
- Build a map of completed vs remaining tasks
- Identify any tasks marked `in_progress` (interrupted — treat as `todo` and re-execute)

Update `docs/progress.md` Phase column to `executing`.

### 4. Run Phase 4: Execution

Follow the process in the story skill's [phase-execution.md](../story/references/phase-execution.md):

#### The Execution Loop

Repeat until all tasks are `done` or all remaining tasks are `blocked`:

```
1. Read story.md Tasks section
2. Find next executable tasks (dependencies satisfied, status: todo)
3. If parallel batch -> launch sub-agents
   If single task -> execute directly
4. After completion -> update story.md, docs/progress.md
5. If new work discovered -> update story.md plan + tasks, continue loop
6. If blocked -> log blocker, skip to next available task
7. Loop back to step 1
```

#### Find Next Executable Tasks

Parse the Tasks section and find all tasks where:
- Status is `todo`
- All tasks listed in Dependencies have status `done`

Group these into:
- **Parallel batch:** Multiple tasks all marked `Parallelizable: true`
- **Sequential task:** A single task, or tasks marked `Parallelizable: false`

#### Execute Parallel Batch

When multiple independent tasks are available, launch one **sub-agent per task** using the Agent tool. Each sub-agent receives:
- The specific task definition (ID, title, description, dependencies, linked criteria, notes)
- The [implementer](../story/references/agents/implementer.md) agent role
- Relevant file paths and code context for that task only
- Project conventions from CLAUDE.md

Each sub-agent does NOT receive: other tasks, accumulated chat history, or tracking file contents.

**Sub-agent prompt template:**
```
You are implementing a single task for story "[story-id]: [title]".

## Your Task
[paste full task definition from story.md]

## Agent Role
[paste implementer.md content]

## Context
[paste relevant code snippets, file paths, conventions]

## Instructions
1. Read the existing code in the affected files
2. Implement the changes described in the task
3. Verify your changes work (run tests if available)
4. Report back: status (Complete/Blocked/Partial), files changed, issues encountered
```

Wait for all sub-agents to complete, then collect results.

#### Execute Sequential Task

When a single task is next (or all tasks are sequential):

1. Update `story.md` frontmatter: `current_task: T{N}`
2. Update the task status in story.md Tasks section: `in_progress`
3. Read the [implementer](../story/references/agents/implementer.md) role
4. Read existing code in the files this task will touch
5. Implement the changes
6. Verify: run tests, type check, or manually verify as appropriate
7. Report result

#### After Each Task Completes

**If Complete:**
- Update task status in story.md Tasks section: `done`
- Increment `completed_tasks` in story.md frontmatter
- Update `current_task` to the next task (or null if done)
- Update `last_updated` in story.md frontmatter
- Update `docs/progress.md`: Phase column stays `executing`, Last Updated column
- Log any implementation decisions in `decisions.md`

**If Blocked:**
- Update task status in story.md Tasks section: `blocked`
- Increment `blocked_tasks` in story.md frontmatter
- Add blocker description to task Notes
- Continue to next available task (don't stop the whole workflow)

**If Partial:**
- Keep task status as `in_progress`
- Note what was completed and what remains in task Notes
- Continue with the remaining work on next iteration

#### Handle Discovered Work

During execution, you may discover:
- A task needs additional sub-tasks
- The plan missed a necessary step
- An assumption was wrong

When this happens:
1. **Stop executing** the current batch
2. Update the plan sections in `story.md` if the scope changed
3. Add new tasks to the Tasks section with proper dependencies
4. Update `total_tasks` in frontmatter
5. Update the execution order diagram
6. Log the discovery in `decisions.md`
7. Resume the execution loop

#### Review Checkpoints

After completing each execution wave (parallel batch or sequential group):
- Briefly review: did the work match the task intent?
- Are there obvious issues visible without deep review?
- If issues found, create fix tasks and add to story.md Tasks section

### 5. Stop

After all tasks are `done` (or all remaining are `blocked`):

- Update `story.md` frontmatter: `current_task: null`
- Update `last_updated`
- Log the execution completion in Phase History
- Update `docs/progress.md` Last Updated column

Do NOT proceed to verification. Do NOT set `current_phase: verifying`.

Present a summary:
```
## Execution Complete for [story-id]

Tasks: X/Y done, Z blocked
Duration: [time span]

Completed:
- T1: [title] - done
- T2: [title] - done
...

Blocked (if any):
- T5: [title] - blocked: [reason]

Next steps:
- /story-verify <id>  — run verification against acceptance criteria
- /story resume <id>  — continue full workflow (includes verification + closeout)
```

## Stopping Conditions

Per [rules.md](../story/references/rules.md) rule 9, stop execution only for:
- Unresolved ambiguity that changes user-visible behavior -> ask the user
- Missing file access or external resource -> report and wait
- Same error 3+ times -> report to user with diagnostics
- Conflict between implementation and approved plan -> report to user

For everything else: make a decision, log it in `decisions.md`, continue.

## Error Handling

- **Story not found in progress.md:** Suggest `/story create --id <id>`
- **No tasks in story.md:** Suggest `/story-tasks <id>` first
- **Plan not approved:** Suggest `/story-init <id>` first
- **All tasks blocked:** Stop and report to user with diagnostics for each blocker
- **Sub-agent failure:** Log the failure, mark task as blocked, continue with next available task

## Rules

Follow [rules.md](../story/references/rules.md) for all tracking and markdown updates.
The autonomous execution rules apply: continue until all tasks are done, stop only for the 4 valid reasons.

All state transitions must:
1. Update `story.md` frontmatter (`current_phase`, `current_task`, `last_updated`, task counters)
2. Log transitions in the Phase History section of `story.md`
3. Update `docs/progress.md` Phase and Last Updated columns after each batch
