---
name: feature
description: "Autonomous feature development workflow. Manages the full SDLC lifecycle: intake, planning (with approval gate), task generation, parallel/sequential execution, verification, and closeout. All state persisted in markdown under docs/features/. Resumable across sessions. Use: /feature new <name>, /feature resume <name>, or /feature to list active features. Triggers on: start feature, new feature, resume feature, continue feature, feature status."
argument-hint: "[new <feature-name> | resume <feature-name> | status]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
---

# Autonomous Feature Workflow

```
┌─────────┐   ┌──────────┐   ┌─────────────────┐   ┌────────────────┐   ┌───────────┐   ┌──────────┐   ┌──────────┐
│  INTAKE  │ → │ PLANNING │ → │ APPROVAL (user)  │ → │ TASK GENERATION│ → │ EXECUTION │ → │ VERIFY   │ → │ CLOSEOUT │
└─────────┘   └──────────┘   └─────────────────┘   └────────────────┘   └───────────┘   └──────────┘   └──────────┘
   Phase 1       Phase 2         Human gate             Phase 3             Phase 4        Phase 5        Phase 6
                              (only pause point)     ←── autonomous after approval ──→
```

## Workflow Resources

All workflow infrastructure is bundled with this plugin. The skill's [references/](references/) directory contains:

- **Rules:** [rules.md](references/rules.md) — the 10 non-negotiable rules
- **Phase instructions:** [phase-intake.md](references/phase-intake.md), [phase-planning.md](references/phase-planning.md), [phase-tasks.md](references/phase-tasks.md), [phase-execution.md](references/phase-execution.md), [phase-verification.md](references/phase-verification.md), [phase-closeout.md](references/phase-closeout.md)
- **Agent roles:** [planner](references/agents/planner.md), [task-breaker](references/agents/task-breaker.md), [implementer](references/agents/implementer.md), [reviewer](references/agents/reviewer.md), [verifier](references/agents/verifier.md), [tracker](references/agents/tracker.md)
- **Resume algorithm:** [resume.md](references/resume.md)

Read the phase reference and agent role before entering each phase.

**Feature templates** are also bundled with the plugin at `docs/features/_template/` (relative to the plugin root). `/feature new` locates and copies them automatically.

## Core Rules

Read [rules.md](references/rules.md) for the complete set. The critical ones:
1. **Markdown is source of truth** — always read feature files before acting
2. **No undefined work** — add to plan/tasks before executing
3. **Autonomous after approval** — don't ask permission per task after plan is approved
4. **Update tracking immediately** — tasks.md and progress.md after every action
5. **Continue until done** — stop only for ambiguity, missing access, repeated failure, or plan conflict

---

## Argument Parsing

Parse `$ARGUMENTS` to determine mode:

### `/feature new <name>`
1. Slugify the name: lowercase, replace spaces with hyphens, remove special chars
2. Check if `docs/features/<slug>/` already exists — if so, tell user and suggest resume
3. Locate the feature templates. Check in order:
   - `docs/features/_template/` in the project root (if `/feature-setup` was used)
   - `~/.claude/plugins/dev-workflow/docs/features/_template/` (plugin bundle)
4. Create `docs/features/<slug>/` in the project and copy all template files into it
5. In each copied file, replace `{{feature-name}}` with the actual feature name and `{{timestamp}}` with current ISO timestamp
6. Begin **Phase 1: Intake**

### `/feature resume <name>`
1. Check if `docs/features/<name>/` exists — if not, tell user and suggest new
2. Follow the [resume algorithm](references/resume.md)
3. Read all feature files, determine current phase, continue from there

### `/feature status`
1. List all directories under `docs/features/` (excluding `_template`)
2. For each, read `progress.md` frontmatter and display: name, current_phase, last_updated
3. Ask if the user wants to resume one or start a new feature

### `/feature` (no arguments)
1. Same as `/feature status` — list features and ask what to do

---

## Phase Dispatch

After determining the mode and current phase, dispatch to the correct phase reference:

| Phase | Status Values | Reference | Primary Agent |
|-------|--------------|-----------|---------------|
| 1. Intake | `intake` | [phase-intake.md](references/phase-intake.md) | [planner](references/agents/planner.md) |
| 2. Planning | `planning`, `pending_approval`, `revising` | [phase-planning.md](references/phase-planning.md) | [planner](references/agents/planner.md) |
| 3. Task Generation | `task_generation` | [phase-tasks.md](references/phase-tasks.md) | [task-breaker](references/agents/task-breaker.md) |
| 4. Execution | `executing` | [phase-execution.md](references/phase-execution.md) | [implementer](references/agents/implementer.md) |
| 5. Verification | `verifying` | [phase-verification.md](references/phase-verification.md) | [verifier](references/agents/verifier.md) |
| 6. Closeout | `closeout` | [phase-closeout.md](references/phase-closeout.md) | [tracker](references/agents/tracker.md) |

**For each phase:** Read the phase reference file and follow its process exactly. Read the agent role file to understand behavioral constraints.

---

## Context Loading Strategy

Load only what's needed for the current phase to conserve context:

| Phase | Always Load | Also Load |
|-------|------------|-----------|
| Intake | progress.md | CLAUDE.md, relevant source files |
| Planning | progress.md, plan.md | acceptance-criteria.md, source files |
| Task Generation | progress.md, plan.md, acceptance-criteria.md | — |
| Execution | progress.md, tasks.md | Current task's relevant source files only |
| Verification | progress.md, tasks.md, acceptance-criteria.md | Implemented source files |
| Closeout | All feature files | — |

**Never load simultaneously:** Multiple features' files. Focus on one feature at a time.

---

## Sub-Agent Delegation Strategy

Use the Agent tool for parallel execution and to keep the main context clean:

| Activity | Delegate? | Why |
|----------|-----------|-----|
| Intake questions, planning | No | Requires accumulated user context |
| Task generation | No | Needs full plan context to be coherent |
| Parallel `[P]` tasks | Yes (one agent per task) | Only way to run tasks concurrently |
| Sequential tasks | Optional | Keeps implementation details out of main context |
| Verification | No | Needs full feature context |
| Closeout | No | Needs full feature context |

**Sub-agent context:** Each sub-agent receives its task definition, the implementer agent role, relevant file paths, and project conventions. It does NOT receive other tasks, chat history, or tracking files.

**Sub-agent result:** Each reports back: status (Complete/Blocked/Partial), files changed, issues encountered. The orchestrator uses this to update tracking docs.

---

## State Machine

The `current_phase` field in `progress.md` YAML frontmatter is the canonical state:

```
Valid transitions:
  intake           → planning
  planning         → pending_approval
  pending_approval → task_generation    (user approved)
  pending_approval → revising           (user requested changes)
  revising         → pending_approval   (changes made, re-presenting)
  task_generation  → executing
  executing        → verifying          (all tasks done)
  executing        → executing          (new work discovered, replanned)
  verifying        → closeout           (all criteria pass)
  verifying        → executing          (gaps found, follow-up tasks created)
  closeout         → complete
```

**Every transition must:**
1. Update `progress.md` frontmatter (`current_phase`, `last_updated`)
2. Log the transition in the Phase History table
3. Update `progress.md` body (Current Status section)

---

## Resume Support

When resuming, follow [resume.md](references/resume.md):
1. Read all feature files
2. Parse `current_phase` from `progress.md` frontmatter
3. Announce the current state to the user
4. Dispatch to the correct phase and continue

For execution phase resume: also parse `current_task` and task statuses to find where to pick up.

---

## Error Handling

- **Feature directory not found:** Suggest `/feature new <name>`
- **Corrupted progress.md:** Reconstruct state from tasks.md and plan.md. Log decision.
- **Sub-agent failure:** Log the failure, mark task as blocked, continue with next available task
- **All tasks blocked:** Stop and report to user with diagnostics
- **Verification loop (gaps → execute → verify → gaps):** If this happens 3+ times, stop and report to user — something fundamental is wrong

---

## File Paths

**Feature data (per-project, relative to project root):**
- Features: `docs/features/<feature-name>/`
- Files per feature: `plan.md`, `tasks.md`, `acceptance-criteria.md`, `progress.md`, `decisions.md`

**Workflow infrastructure (bundled with plugin):**
- All references, agents, phases, and rules are in this skill's `references/` directory
- Templates are in `docs/features/_template/` relative to the plugin root
- No project-level setup required
