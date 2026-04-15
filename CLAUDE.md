# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Claude Code plugin** implementing an autonomous feature development workflow. It manages the full SDLC lifecycle (intake → planning → task generation → execution → verification → closeout) with persistent markdown state tracking.

**GitHub repo:** `nogueiraever/dev-workflow`

## Installation & Distribution

```bash
# Local install — symlinks skills into ~/.claude/skills/ and copies infra to ~/.dev-workflow/
./install.sh

# Build distributable package → ./dist/feature-workflow/
./scripts/build-plugin.sh
```

## Plugin Structure

```
skills/               # 6 Claude Code slash commands
  feature/            # Main orchestrator (full lifecycle)
  feature-init/       # Phases 1-2 only (intake + planning)
  feature-tasks/      # Phase 3 only (task generation)
  feature-execute/    # Phase 4 only (execution)
  feature-verify/     # Phase 5 only (verification)
  feature-setup/      # One-time project initialization
.dev-workflow/        # Workflow infrastructure (copied to ~/.dev-workflow on install)
  agents/             # 6 agent role definitions
  orchestrators/
  prompts/
  rules/
docs/features/_template/   # Per-feature markdown templates
```

## Skill Architecture

Each skill's logic lives in `skills/<name>/SKILL.md`. The main `/feature` skill is a 6-phase state machine:

| Phase | State Value | Key Output |
|-------|-------------|------------|
| 1. Intake | `intake` | Requirements gathered, scope understood |
| 2. Planning | `planning` → `pending_approval` | `plan.md` + `acceptance-criteria.md` |
| 3. Task Generation | `task_generation` | `tasks.md` with dependency graph |
| 4. Execution | `executing` | Code changes, updated `tasks.md` |
| 5. Verification | `verifying` | Verified against acceptance criteria |
| 6. Closeout | `closeout` → `complete` | Final summary |

**Approval gate:** Phase 2→3 transition requires explicit user approval. After that, execution is fully autonomous.

## Per-Feature State Files

Each feature tracked in `docs/features/<feature-name>/` (relative to the *target project*, not this repo):

- `progress.md` — Canonical state: `current_phase` in frontmatter drives resume logic
- `plan.md` — Scope, affected modules, APIs, implementation strategy
- `acceptance-criteria.md` — Testable criteria organized by behavior category
- `tasks.md` — Atomic tasks with IDs (T1, T2...), dependency map, parallelizable flags
- `decisions.md` — Append-only log of implementation decisions with rationale

## Workflow Infrastructure (.dev-workflow/)

### Agent Roles (agents/)
Six specialized agents with strict responsibilities:

| Agent | Responsibility |
|-------|---------------|
| `planner.md` | Clarifies scope, generates `plan.md` and `acceptance-criteria.md` |
| `task-breaker.md` | Converts plan into atomic tasks with dependency graph |
| `implementer.md` | Executes a single task; follows existing codebase patterns |
| `reviewer.md` | Verifies task output matches intent; flags security/quality issues |
| `verifier.md` | Validates implementation against acceptance criteria |
| `tracker.md` | Updates tracking files (`tasks.md`, `progress.md`, `decisions.md`) |

### Core Rules (rules/core-rules.md)
10 non-negotiable workflow rules — key ones:
- Markdown is source of truth (not chat memory)
- Update `tasks.md` immediately after each task (never batch)
- Stop only for: unresolved ambiguity affecting behavior, missing access, repeated failure (3+), plan conflict
- Discovered work → update plan/tasks, then resume (never silently change scope)

### Phase Instructions (in `skills/feature/references/`)
Detailed per-phase instructions (`phase-intake.md`, `phase-planning.md`, etc.) specify what to load, what to do, and valid state transitions.

## State Transitions

```
intake → planning → pending_approval ←→ revising
pending_approval → task_generation → executing ←→ verifying → closeout → complete
```

`executing` can loop back to `executing` if new work is discovered (replan triggers).
`verifying` can loop back to `executing` if gaps are found.

## Parallel Execution

Tasks marked `parallelizable: true` in `tasks.md` run concurrently via the `Agent` tool. Sequential tasks run one at a time. The orchestrator delegates parallel tasks to sub-agents with: task definition, agent role, relevant file paths, and project conventions — but NOT chat history or other tasks.

## Resume Algorithm

On `/feature <name>` when feature directory exists:
1. Load all feature files
2. Parse `current_phase` from `progress.md` frontmatter
3. Dispatch to the correct phase handler
4. For `executing`: rebuild dependency graph, find next unblocked tasks, continue

## Manual Entrypoints

The sub-skills allow granular control over the workflow:
- `/feature-init` — Run only intake + planning; stop before task generation
- `/feature-tasks` — Generate tasks from an already-approved plan; stop before execution
- `/feature-execute` — Execute existing tasks; stop before verification
- `/feature-verify` — Verify implementation; stop before closeout
- `/feature-setup` — Copy `.dev-workflow/` and templates into the current project (safe to re-run)
