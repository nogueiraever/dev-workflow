# Story Orchestrator

This is the main workflow entrypoint for autonomous story development. It coordinates all 6 phases, delegates to agents, and manages the state machine.

A story may belong to an epic. When it does, the story files are stored in the epic's `stories/` folder (e.g., `docs/epics/HRAB-7000/stories/HRAB-7026/`). Standalone stories live at a top-level path (e.g., `docs/stories/HRAB-7026/`). In both cases, the canonical path is recorded in `docs/progress.md`.

---

## State Machine

```
┌─────────┐   ┌──────────┐   ┌─────────────────┐   ┌────────────────┐   ┌───────────┐   ┌──────────┐   ┌──────────┐
│  INTAKE  │ → │ PLANNING │ → │ PENDING APPROVAL │ → │ TASK GENERATION│ → │ EXECUTION │ → │ VERIFY   │ → │ CLOSEOUT │
└─────────┘   └──────────┘   └─────────────────┘   └────────────────┘   └───────────┘   └──────────┘   └──────────┘
   Phase 1       Phase 2         Human gate             Phase 3             Phase 4        Phase 5        Phase 6
```

### Valid State Transitions

```
intake           → planning
planning         → pending_approval
pending_approval → task_generation      (user approved)
pending_approval → revising             (user requested changes)
revising         → pending_approval     (re-presenting updated plan)
task_generation  → executing
executing        → verifying            (all tasks done)
executing        → executing            (replanned, new tasks added)
verifying        → closeout             (all criteria pass)
verifying        → executing            (gaps found, follow-up tasks)
closeout         → complete
```

Every transition must:
1. Update `story.md` frontmatter (`current_phase`, `last_updated`)
2. Log the transition in the Phase History table in `story.md`
3. Update the story's Phase column in `docs/progress.md`

---

## Phase 1 — Intake

**Agent:** [planner](../agents/planner.md)
**Prompt:** [story-intake](../prompts/story-intake.md)
**Rules:** [core-rules](../rules/core-rules.md)

### Process
1. Parse the user's story request
2. Explore the codebase to understand affected areas
3. Identify gaps in understanding
4. Ask clarifying questions ONLY if genuinely ambiguous
5. Write initial notes into `story.md` (Summary, Affected Pages/Modules, Assumptions)
6. Transition to `planning`

### Exit Criteria
- Story request understood
- Codebase explored
- Critical ambiguities resolved
- `story.md` frontmatter shows `current_phase: planning`

---

## Phase 2 — Planning

**Agent:** [planner](../agents/planner.md)
**Prompt:** [plan-generation](../prompts/plan-generation.md)
**Rules:** [core-rules](../rules/core-rules.md)

### Process
1. Generate complete plan sections in `story.md` (all sections filled)
2. Generate `acceptance-criteria.md` with testable criteria
3. Set `story.md` frontmatter status to `pending_approval`
4. Present plan to user
5. **STOP AND WAIT FOR USER RESPONSE**

### On User Response
- **Approved:** Set `story.md` status → `approved`, transition to `task_generation`
- **Changes requested:** Set phase → `revising`, apply changes, re-present

### Exit Criteria
- `story.md` status is `approved`
- `acceptance-criteria.md` has criteria for all scope items
- User has explicitly approved

---

## Phase 3 — Task Generation

**Agent:** [task-breaker](../agents/task-breaker.md)
**Prompt:** [task-generation](../prompts/task-generation.md)
**Rules:** [core-rules](../rules/core-rules.md)

### Process
1. Read approved plan sections and acceptance criteria
2. Break into atomic tasks with all required fields
3. Map dependencies between tasks
4. Identify parallel vs sequential groups
5. Build execution order diagram
6. Write tasks as `### T{N}:` headings in the Tasks section of `story.md`
7. Update `story.md` frontmatter counters
8. Transition to `executing`

### Exit Criteria
- All tasks defined with complete fields
- Every scope item maps to at least one task
- No circular dependencies
- `story.md` frontmatter shows `current_phase: executing`

---

## Phase 4 — Execution

**Agents:** [implementer](../agents/implementer.md), [tracker](../agents/tracker.md), [reviewer](../agents/reviewer.md)
**Prompt:** [execution-engine](../prompts/execution-engine.md)
**Rules:** [core-rules](../rules/core-rules.md)

### Process (The Execution Loop)
```
REPEAT:
  1. Read story.md Tasks section
  2. Find executable tasks (dependencies satisfied, status: todo)
  3. Parallel batch → launch sub-agents (one per task)
     Sequential task → execute directly
  4. After completion → update story.md (task statuses, frontmatter), decisions.md
  5. After meaningful batches → update docs/progress.md Phase column
  6. New work discovered → update plan/tasks in story.md, continue loop
  7. Blocked → log blocker, skip to next available task
UNTIL all tasks are done
```

### Parallel Execution
- Launch one sub-agent per task using the Agent tool
- Each sub-agent gets: task definition, implementer role, relevant code context
- Sub-agent does NOT get: other tasks, chat history, tracking files
- Collect results, update tracking docs

### Stopping Conditions (from core-rules.md Rule 9)
- Unresolved ambiguity changing behavior → ask user
- Missing access → report and wait
- Same error 3+ times → report with diagnostics
- Plan conflict → report to user

### Exit Criteria
- All tasks `done` (or `blocked` with logged reasons)
- Tracking docs fully updated
- Transition to `verifying`

---

## Phase 5 — Verification

**Agent:** [verifier](../agents/verifier.md)
**Prompt:** [verification](../prompts/verification.md)
**Rules:** [core-rules](../rules/core-rules.md)

### Process
1. Verify all tasks are truly `done`
2. Walk through each acceptance criterion → pass/fail/skip
3. Run automated checks (tests, type check, lint)
4. Check for regressions
5. Assess gaps

### Routing
- **All pass:** Transition to `closeout`
- **Gaps found:** Generate follow-up tasks, return to `executing`
- **Verification loop 3+ times:** Stop and report to user

### Exit Criteria
- Every criterion has a status (no `pending` remaining)
- Automated checks pass
- `story.md` frontmatter shows `current_phase: closeout`

---

## Phase 6 — Closeout

**Agent:** [tracker](../agents/tracker.md)
**Rules:** [core-rules](../rules/core-rules.md)

### Process
1. Compile final summary in `story.md` Phase History
2. List all completed tasks
3. Document any remaining/blocked items
4. Summarize key decisions
5. Set `current_phase: complete` in `story.md` frontmatter
6. Update `docs/progress.md` — set story Status to `complete`, update Phase column
7. Present final summary to user

### Exit Criteria
- `story.md` has complete Phase History
- `story.md` status is `complete`
- `docs/progress.md` reflects completion
- User has been presented the summary

---

## Resume Support

When resuming a story in a new session:

**Prompt:** [resume-story](../prompts/resume-story.md)

1. Look up story ID in `docs/progress.md` to resolve the file path
2. Read ALL files at the resolved path: `story.md`, `acceptance-criteria.md`, `decisions.md`
3. Parse `current_phase` from `story.md` frontmatter
4. Announce current state to user
5. Dispatch to the correct phase above
6. Continue from where work left off

For execution phase resume:
- Parse `current_task` and task statuses from `story.md` Tasks section
- Find first `todo` task with satisfied dependencies
- Handle any `in_progress` (interrupted) task
- Continue the execution loop

---

## Sub-Agent Delegation Strategy

| Activity | Delegate? | Reason |
|----------|-----------|--------|
| Intake + planning | No | Needs accumulated user context |
| Task generation | No | Needs full plan context |
| Parallel tasks | Yes (one per task) | Only way to run concurrently |
| Sequential tasks | Optional | Keeps implementation out of main context |
| Verification | No | Needs full story context |
| Closeout | No | Needs full story context |

---

## Context Loading Strategy

| Phase | Always Load | On-Demand |
|-------|------------|-----------|
| Intake | story.md | CLAUDE.md, source files |
| Planning | story.md, acceptance-criteria.md | source files |
| Task Generation | story.md, acceptance-criteria.md | — |
| Execution | story.md | Current task's source files only |
| Verification | story.md, acceptance-criteria.md | Source files |
| Closeout | All story files | — |

Note: `story.md` replaces the old separate loading of `plan.md` + `progress.md` + `tasks.md`. Always load `story.md` — it contains the plan, frontmatter state, and task breakdown in one file.

---

## Epic Integration

- A story's `epic` field in `story.md` frontmatter links it to a parent epic
- Stories belonging to an epic are stored under the epic's `stories/` directory
- The `docs/progress.md` global index tracks both epics and stories
- When completing a story, check if the parent epic's Linked Stories table needs updating
- Epic status is derived from its constituent stories (all stories complete → epic can be closed)

---

## Error Recovery

| Error | Recovery |
|-------|----------|
| Story directory not found | Check docs/progress.md for path; suggest creating a new story |
| Corrupted story.md frontmatter | Reconstruct state from Tasks section + acceptance-criteria.md |
| Story not in docs/progress.md | Add row to global index, then continue |
| Sub-agent failure | Mark task blocked, continue with next |
| All tasks blocked | Stop and report to user |
| Verification loop (3+ cycles) | Stop and report — something fundamental is wrong |
