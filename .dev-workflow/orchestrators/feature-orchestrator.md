# Feature Orchestrator

This is the main workflow entrypoint for autonomous feature development. It coordinates all 6 phases, delegates to agents, and manages the state machine.

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
1. Update `progress.md` frontmatter (`current_phase`, `last_updated`)
2. Log the transition in the Phase History table
3. Update the Current Status section in `progress.md`

---

## Phase 1 — Intake

**Agent:** [planner](../agents/planner.md)
**Prompt:** [feature-intake](../prompts/feature-intake.md)
**Rules:** [core-rules](../rules/core-rules.md)

### Process
1. Parse the user's feature request
2. Explore the codebase to understand affected areas
3. Identify gaps in understanding
4. Ask clarifying questions ONLY if genuinely ambiguous
5. Write initial notes into `plan.md`
6. Transition to `planning`

### Exit Criteria
- Feature request understood
- Codebase explored
- Critical ambiguities resolved
- `progress.md` shows `current_phase: planning`

---

## Phase 2 — Planning

**Agent:** [planner](../agents/planner.md)
**Prompt:** [plan-generation](../prompts/plan-generation.md)
**Rules:** [core-rules](../rules/core-rules.md)

### Process
1. Generate complete `plan.md` (all sections filled)
2. Generate `acceptance-criteria.md` with testable criteria
3. Set status to `pending_approval`
4. Present plan to user
5. **STOP AND WAIT FOR USER RESPONSE**

### On User Response
- **Approved:** Set `plan.md` status → `approved`, transition to `task_generation`
- **Changes requested:** Set phase → `revising`, apply changes, re-present

### Exit Criteria
- `plan.md` status is `approved`
- `acceptance-criteria.md` has criteria for all scope items
- User has explicitly approved

---

## Phase 3 — Task Generation

**Agent:** [task-breaker](../agents/task-breaker.md)
**Prompt:** [task-generation](../prompts/task-generation.md)
**Rules:** [core-rules](../rules/core-rules.md)

### Process
1. Read approved plan and acceptance criteria
2. Break into atomic tasks with all required fields
3. Map dependencies between tasks
4. Identify parallel vs sequential groups
5. Build execution order diagram
6. Update `tasks.md` frontmatter counters
7. Transition to `executing`

### Exit Criteria
- All tasks defined with complete fields
- Every scope item maps to at least one task
- No circular dependencies
- `progress.md` shows `current_phase: executing`

---

## Phase 4 — Execution

**Agents:** [implementer](../agents/implementer.md), [tracker](../agents/tracker.md), [reviewer](../agents/reviewer.md)
**Prompt:** [execution-engine](../prompts/execution-engine.md)
**Rules:** [core-rules](../rules/core-rules.md)

### Process (The Execution Loop)
```
REPEAT:
  1. Read tasks.md
  2. Find executable tasks (dependencies satisfied, status: todo)
  3. Parallel batch → launch sub-agents (one per task)
     Sequential task → execute directly
  4. After completion → update tasks.md, progress.md, decisions.md
  5. New work discovered → update plan/tasks, continue loop
  6. Blocked → log blocker, skip to next available task
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
- `progress.md` shows `current_phase: closeout`

---

## Phase 6 — Closeout

**Agent:** [tracker](../agents/tracker.md)
**Rules:** [core-rules](../rules/core-rules.md)

### Process
1. Compile final summary in `progress.md`
2. List all completed tasks
3. Document any remaining/blocked items
4. Summarize key decisions
5. Set `current_phase: complete`
6. Present final summary to user

### Exit Criteria
- `progress.md` has complete final summary
- `plan.md` status is `complete`
- Phase History table is complete
- User has been presented the summary

---

## Resume Support

When resuming a feature in a new session:

**Prompt:** [resume-feature](../prompts/resume-feature.md)

1. Read ALL files in `docs/features/<feature-name>/`
2. Parse `current_phase` from `progress.md` frontmatter
3. Announce current state to user
4. Dispatch to the correct phase above
5. Continue from where work left off

For execution phase resume:
- Parse `current_task` and task statuses
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
| Verification | No | Needs full feature context |
| Closeout | No | Needs full feature context |

---

## Context Loading Strategy

| Phase | Always Load | On-Demand |
|-------|------------|-----------|
| Intake | progress.md | CLAUDE.md, source files |
| Planning | progress.md, plan.md | acceptance-criteria.md, source files |
| Task Generation | progress.md, plan.md, acceptance-criteria.md | — |
| Execution | progress.md, tasks.md | Current task's source files only |
| Verification | progress.md, tasks.md, acceptance-criteria.md | Source files |
| Closeout | All feature files | — |

---

## Error Recovery

| Error | Recovery |
|-------|----------|
| Feature directory not found | Suggest creating a new feature |
| Corrupted progress.md | Reconstruct state from tasks.md + plan.md |
| Sub-agent failure | Mark task blocked, continue with next |
| All tasks blocked | Stop and report to user |
| Verification loop (3+ cycles) | Stop and report — something fundamental is wrong |
