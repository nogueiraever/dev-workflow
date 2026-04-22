# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Claude Code plugin** implementing an autonomous story-driven development workflow. It manages the full SDLC lifecycle (intake → planning → task generation → execution → verification → closeout) with persistent markdown state tracking. Supports Jira-style external IDs, epic grouping, and multi-developer parallel work.

**GitHub repo:** `nogueiraever/dev-workflow`

## Concepts

| Concept | Description |
|---------|-------------|
| **Epic** | Large initiative grouping related stories. Optional higher-level container. |
| **Story** | Main delivery unit. Goes through the full 6-phase lifecycle. |
| **Task** | Smallest implementation unit, tracked inside a story's task checklist. |

## Installation & Distribution

```bash
# Local install — symlinks skills into ~/.claude/skills/ and copies infra to ~/.dev-workflow/
./install.sh

# Build distributable package → ./dist/dev-workflow/
./scripts/build-plugin.sh
```

## Plugin Structure

```
skills/                # Claude Code slash commands
  story/               # Main story orchestrator (full lifecycle)
  story-init/          # Phases 1-2 only (intake + planning)
  story-tasks/         # Phase 3 only (task generation)
  story-execute/       # Phase 4 only (execution)
  story-verify/        # Phase 5 only (verification)
  task/                # Minor story-scoped adjustments with planning + approval gate
  epic/                # Epic management (create, resume, list, status)
  workflow-setup/      # One-time project initialization
  feature/             # Deprecated — redirects to /story
  feature-init/        # Deprecated — redirects to /story-init
  feature-tasks/       # Deprecated — redirects to /story-tasks
  feature-execute/     # Deprecated — redirects to /story-execute
  feature-verify/      # Deprecated — redirects to /story-verify
  feature-setup/       # Deprecated — redirects to /workflow-setup
.dev-workflow/         # Workflow infrastructure (copied to ~/.dev-workflow on install)
  agents/              # 6 agent role definitions
  orchestrators/       # Story orchestrator
  prompts/             # Phase-specific prompts
  rules/               # Core workflow rules
  templates/           # Templates for story.md, epic.md, progress.md, etc.
```

## Identifier Model

Two kinds of IDs are supported:

1. **External IDs** — provided by the user (e.g., `HRAB-7026`, `ABC-1234`, `PLAT-1842`)
2. **Internal IDs** — auto-generated when the user doesn't provide an ID (`E<n>` for epics, `S<n>` for stories, `T<n>` for tasks)

IDs are globally unique within their type. Resolution is done through `docs/progress.md`.

## Folder Structure (in target projects)

```
project/
├── docs/
│   └── progress.md                          # Global index of all epics and stories
├── epics/
│   └── {id}-{slug}/
│       ├── epic.md                          # Epic definition
│       └── stories/
│           └── {id}-{slug}/
│               ├── story.md                 # Story: plan + tasks + state (unified)
│               ├── acceptance-criteria.md    # Testable criteria
│               └── decisions.md             # Decision log
└── stories/
    └── {id}-{slug}/
        ├── story.md
        ├── acceptance-criteria.md
        └── decisions.md
```

## Skill Architecture

Each skill's logic lives in `skills/<name>/SKILL.md`. The main `/story` skill is a 6-phase state machine:

| Phase | State Value | Key Output |
|-------|-------------|------------|
| 1. Intake | `intake` | Requirements gathered, scope understood |
| 2. Planning | `planning` → `pending_approval` | `story.md` plan sections + `acceptance-criteria.md` |
| 3. Task Generation | `task_generation` | Tasks section in `story.md` with dependency graph |
| 4. Execution | `executing` | Code changes, updated task statuses in `story.md` |
| 5. Verification | `verifying` | Verified against acceptance criteria |
| 6. Closeout | `closeout` → `complete` | Final summary |

**Approval gate:** Phase 2→3 transition requires explicit user approval. After that, execution is fully autonomous.

## Story State (story.md)

Each story's state is tracked in a single `story.md` file that combines plan, tasks, and phase state:

- **Frontmatter** — `id`, `id_source`, `title`, `status`, `epic`, `owner`, `current_phase`, `current_task`, `total_tasks`, `completed_tasks`, `blocked_tasks`, `depends_on`, `created`, `last_updated`
- **Plan sections** — Summary, Context, Scope, Out of Scope, Assumptions, Risks, Implementation Plan
- **Tasks section** — Execution Order diagram + task entries (### T1: Title) with status, dependencies, description
- **Phase History** — table tracking all phase transitions with timestamps

`story.md` frontmatter `current_phase` drives the resume logic. This replaces the old separate `plan.md`, `progress.md`, and `tasks.md` files.

Supporting files remain separate:
- `acceptance-criteria.md` — Testable criteria organized by behavior category
- `decisions.md` — Append-only log of implementation decisions with rationale

## Global Progress Index (docs/progress.md)

Central file tracking all epics and stories:

| Table | Columns |
|-------|---------|
| Epics | ID, Source, Title, Status, Owner, Stories (count), Path |
| Stories | ID, Source, Title, Status, Owner, Epic, Phase, Path |

Used for ID→path resolution, project overview, and multi-developer coordination.

## Workflow Infrastructure (.dev-workflow/)

### Agent Roles (agents/)
Six specialized agents with strict responsibilities:

| Agent | Responsibility |
|-------|---------------|
| `planner.md` | Clarifies scope, generates story plan and `acceptance-criteria.md` |
| `task-breaker.md` | Converts plan into atomic tasks with dependency graph |
| `implementer.md` | Executes a single task; follows existing codebase patterns |
| `reviewer.md` | Verifies task output matches intent; flags security/quality issues |
| `verifier.md` | Validates implementation against acceptance criteria |
| `tracker.md` | Updates `story.md`, `decisions.md`, and `docs/progress.md` |

### Core Rules (rules/core-rules.md)
11 non-negotiable workflow rules — key ones:
- Markdown is source of truth (not chat memory)
- Update `story.md` task statuses immediately after each task (never batch)
- Stop only for: unresolved ambiguity affecting behavior, missing access, repeated failure (3+), plan conflict
- Discovered work → update plan/tasks, then resume (never silently change scope)
- Maintain `docs/progress.md` global index after every phase transition and meaningful batch

### Phase Instructions (in `skills/story/references/`)
Detailed per-phase instructions (`phase-intake.md`, `phase-planning.md`, etc.) specify what to load, what to do, and valid state transitions.

## State Transitions

```
intake → planning → pending_approval ←→ revising
pending_approval → task_generation → executing ←→ verifying → closeout → complete
```

`executing` can loop to `pending_approval` via `/task` when minor story adjustments are requested.
`verifying` can also loop to `pending_approval` for approved follow-up adjustments.

## Parallel Execution

Tasks marked `parallelizable: true` in `story.md` run concurrently via the `Agent` tool. Sequential tasks run one at a time. The orchestrator delegates parallel tasks to sub-agents with: task definition, agent role, relevant file paths, and project conventions — but NOT chat history or other tasks.

## Resume Algorithm

On `/story resume <id>`:
1. Resolve story path from `docs/progress.md`
2. Load `story.md`, `acceptance-criteria.md`, `decisions.md`
3. Parse `current_phase` from `story.md` frontmatter
4. Dispatch to the correct phase handler
5. For `executing`: rebuild dependency graph from Tasks section, find next unblocked tasks, continue

## Commands

### Story commands
- `/story create [--id X] [--epic Y] [--title "Z"]` — Create a new story
- `/story resume <id>` — Resume by ID
- `/story <id>` — Smart routing (resume if exists, offer create if not)
- `/story list` — List all stories
- `/story status <id>` — Detailed story status
- `/task [--story <id>] <request>` — Add a small adjustment to the active story, run planner with story context, and wait for approval before execution

### Epic commands
- `/epic create [--id X] [--title "Z"] [--no-import] [--no-plan]` — Create an epic. When `--id` is an external Jira ID, automatically fetches epic details, imports all child stories, and plans each story (fills plan sections, generates acceptance criteria). Use `--no-import` to skip Jira fetch, `--no-plan` to import without planning.
- `/epic plan <id>` — Plan all unplanned stories in an epic. Runs the planner on each story in `intake`/`planning` phase, filling implementation details and acceptance criteria. Plans are presented for batch approval.
- `/epic resume <id>` — Show epic with linked stories
- `/epic list` — List all epics

### Manual entrypoints
- `/story-init <id>` — Run only intake + planning; stop before task generation
- `/story-tasks <id>` — Generate tasks from an already-approved plan; stop before execution
- `/story-execute <id>` — Execute existing tasks; stop before verification
- `/story-verify <id>` — Verify implementation; stop before closeout
- `/workflow-setup` — Copy `.dev-workflow/` and templates into the current project (safe to re-run)

### Deprecated commands
The old `/feature*` commands still work as thin wrappers that redirect to the corresponding `/story*` or `/workflow-setup` commands.
