# Phase 4: Execution

**Status value:** `executing`
**Agents:** [implementer](agents/implementer.md), [tracker](agents/tracker.md), [reviewer](agents/reviewer.md)

## Objective

Execute all tasks autonomously, updating markdown tracking continuously. Use parallel execution when tasks are independent, sequential when dependencies exist. This is the longest phase and the core of the workflow.

## Process

### The Execution Loop

Repeat until all tasks are `done`:

```
1. Read story.md Tasks section
2. Find next executable tasks (dependencies satisfied, status: todo)
3. If parallel batch → launch sub-agents
   If single task → execute directly
4. After completion → update story.md (task status + frontmatter counters)
5. If new work discovered → update plan sections + Tasks section in story.md, continue loop
6. If blocked → log blocker, skip to next available task
7. Loop back to step 1
```

### 1. Find Next Executable Tasks

Parse the Tasks section in `story.md` and find all tasks where:
- Status is `todo`
- All tasks listed in `Dependencies` have status `done`

Group these into:
- **Parallel batch:** Multiple tasks all marked `parallelizable: true`
- **Sequential task:** A single task, or tasks marked `parallelizable: false`

### 2. Execute Parallel Batch

When multiple independent tasks are available:

Launch one **sub-agent per task** using the Agent tool. Each sub-agent receives:
- The specific task definition (ID, title, description, dependencies, linked criteria, notes)
- The [implementer](agents/implementer.md) agent role
- Relevant file paths and code context for that task only
- Project conventions from CLAUDE.md

Each sub-agent does NOT receive: other tasks, accumulated chat history, or tracking file contents.

**Sub-agent prompt template:**
```
You are implementing a single task for story "[story-id]: [title]".

## Your Task
[paste full task definition from story.md Tasks section]

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

### 3. Execute Sequential Task

When a single task is next (or all tasks are sequential):

1. Update `story.md` frontmatter: `current_task: T{N}`
2. Update the task status in `story.md` Tasks section: `in_progress`
3. Read the [implementer](agents/implementer.md) role
4. Read existing code in the files this task will touch
5. Implement the changes
6. Verify: run tests, type check, or manually verify as appropriate
7. Report result

### 4. After Each Task Completes

For each completed task (whether from sub-agent or direct execution):

**If Complete:**
- Update task status in `story.md` Tasks section: `done`
- Recount and update `story.md` frontmatter: `completed_tasks`, `current_task`, `last_updated`
- Update the Current Status section in `story.md`: add to Completed Items, update next steps
- Update `docs/progress.md`: Phase column, Last Updated
- Log any implementation decisions in `decisions.md`

**If Blocked:**
- Update task status in `story.md` Tasks section: `blocked`
- Recount and update `story.md` frontmatter: `blocked_tasks`
- Add blocker description to task Notes
- Update the Current Status section in `story.md`: add to Blocked Items
- Continue to next available task (don't stop the whole workflow)

**If Partial:**
- Keep task status as `in_progress`
- Note what was completed and what remains in task Notes
- Continue with the remaining work on next iteration

### 5. Handle Discovered Work

During execution, you may discover:
- A task needs additional sub-tasks
- The plan missed a necessary step
- An assumption was wrong

When this happens:
1. **Stop executing** the current batch
2. Update the plan sections in `story.md` if the scope changed
3. Add new tasks to the Tasks section in `story.md` with proper dependencies
4. Update the Execution Order diagram
5. Update `story.md` frontmatter: `total_tasks`
6. Log the discovery in `decisions.md`
7. Resume the execution loop

### 6. Review Checkpoints

After completing each execution wave (parallel batch or sequential group):
- Briefly review: did the work match the task intent?
- Are there obvious issues visible without deep review?
- If issues found, create fix tasks and add to the Tasks section in `story.md`

Full formal review happens in Phase 5 (Verification).

## Stopping Conditions

Per [rules.md](rules.md) rule 9, stop execution only for:
- Unresolved ambiguity that changes user-visible behavior → ask the user
- Missing file access or external resource → report and wait
- Same error 3+ times → report to user with diagnostics
- Conflict between implementation and approved plan → report to user

For everything else: make a decision, log it in `decisions.md`, continue.

## Exit Criteria

- All tasks in the Tasks section of `story.md` have status `done` (or `blocked` with logged reasons)
- `story.md` frontmatter and Current Status section reflect all completed work
- `decisions.md` captures all implementation decisions
- `docs/progress.md` is up to date
- Transition to `verifying` phase
