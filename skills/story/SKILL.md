---
name: story
description: "Autonomous story development workflow using Epic > Story > Task hierarchy. Manages the full SDLC lifecycle: intake, planning (with approval gate), task generation, parallel/sequential execution, verification, and closeout. All state persisted in markdown. Resumable across sessions. Use: /story create, /story resume <id>, /story <id>, /story list, /story status <id>. Triggers on: start story, new story, resume story, continue story, story status."
argument-hint: "[create [--id ID] [--epic EPIC] [--title TITLE] | resume <id> | <id> | <freeform description> | list | status <id>]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
  - AskUserQuestion
---

# Autonomous Story Workflow

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

**Story templates** are installed at `~/.dev-workflow/docs/stories/_template/`. `/story create` locates and copies them automatically.

## Core Rules

Read [rules.md](references/rules.md) for the complete set. The critical ones:
1. **Markdown is source of truth** — always read story files before acting
2. **No undefined work** — add to story.md tasks before executing
3. **Autonomous after approval** — don't ask permission per task after plan is approved
4. **Update tracking immediately** — story.md and docs/progress.md after every action
5. **Continue until done** — stop only for ambiguity, missing access, repeated failure, or plan conflict

---

## Argument Parsing

Parse `$ARGUMENTS` to determine mode:

### `/story create [--id HRAB-7026] [--epic HRAB-7000] [--title "Global progress tracking"]` — create a new story

1. Parse flags:
   - `--id <ID>` — external ticket ID (optional). If provided, `id_source: external`. If omitted, generate internal ID.
   - `--epic <EPIC-ID>` — parent epic ID (optional). Determines directory placement.
   - `--title <TITLE>` — story title (optional). If omitted, prompt the user during intake.

2. **Generate internal ID** (when `--id` is not provided):
   - Read `docs/progress.md` and scan the ID column for entries matching `S<number>`
   - Find the highest number, increment by 1 → new ID is `S{N+1}`
   - If no internal IDs exist yet, start at `S1`
   - Set `id_source: internal`

3. **Generate slug** from the title:
   - Lowercase the title
   - Replace spaces with hyphens
   - Strip special characters (keep alphanumeric and hyphens only)
   - Truncate to max 50 characters
   - If no title provided yet, use the ID as a temporary slug

4. **Determine story path:**
   - If `--epic` provided: `epics/{epic-id}-{epic-slug}/stories/{story-id}-{slug}/`
   - If no `--epic`: `docs/stories/{story-id}-{slug}/`

5. **Create story directory and files:**
   - Locate templates: check `docs/stories/_template/` in project root, then `~/.dev-workflow/docs/stories/_template/`
   - Create the story directory
   - Create `story.md` from template with frontmatter populated:
     ```yaml
     ---
     id: "<ID>"
     id_source: external  # or "internal"
     title: "<TITLE>"
     status: active
     epic: "<EPIC-ID>"  # or null for standalone
     owner: "@enogueira"
     current_phase: intake
     current_task: null
     total_tasks: 0
     completed_tasks: 0
     blocked_tasks: 0
     depends_on: []
     created: "<ISO-TIMESTAMP>"
     last_updated: "<ISO-TIMESTAMP>"
     ---
     ```
   - Create `acceptance-criteria.md` from template
   - Create `decisions.md` from template

6. **Register in global index:**
   - Add a row to `docs/progress.md` with: ID, Title, Status (active), Phase (intake), Path, Created, Last Updated
   - If `docs/progress.md` doesn't exist, create it with the table header

7. **Begin Phase 1: Intake**

### `/story resume <id>` — explicit resume

1. Resolve the story path from `docs/progress.md`:
   - Search the ID column for a row matching `<id>` (case-insensitive)
   - Extract the Path column value
   - If not found, tell the user and suggest `/story create --id <id>`
2. Follow the [resume algorithm](references/resume.md)
3. Read all story files, determine current phase, continue from there

### `/story <arg>` — smart routing (resume, create-by-id, or create-from-description)

1. Classify the argument:
   - **ID pattern** — matches `S<number>` or contains a hyphen with letters+numbers (e.g., `HRAB-7026`, `PLAT-42`). Short, no spaces, no URLs, no sentence-style text.
   - **Freeform description** — anything else: a phrase, sentence, paragraph, or a description that contains spaces, URLs, `@path/` mentions, or file references. Treat as "the user is asking to start a new story, and this text is the seed context."

2. **If ID pattern:** search `docs/progress.md` for a row where the ID column matches:
   - **Found** → resume: resolve path, read story files, parse `current_phase` from `story.md`, follow [resume algorithm](references/resume.md), continue from that phase.
   - **Not found** → offer to create: "No story found with ID `<id>`. Would you like to create it? Use `/story create --id <id> --title \"<title>\"`" — then stop. Do not create the story automatically.

3. **If freeform description:** route to **create-from-description** mode:
   - Generate an internal ID (`S<N+1>` per the rule in `/story create`).
   - Derive a provisional title from the first ~10 words of the description (strip URLs and `@` mentions for the slug; keep them in the description body).
   - Create the story directory and `story.md` using the same template as `/story create`, with frontmatter `current_phase: intake` and the freeform text seeded into the Context section of `story.md` and into `decisions.md` as the originating brief.
   - Register the row in `docs/progress.md`.
   - **Enter Phase 1: Intake.** Intake's job is to ask clarifying questions (scope, acceptance criteria, out-of-scope, constraints) — never to start execution. The approval gate in Phase 2 (see [phase-planning.md](references/phase-planning.md) and [rules.md](references/rules.md) Rule 11) still applies.
   - **Do NOT** skip intake, do NOT jump to `task_generation`, and do NOT start executing. A freeform argument is a *starting point for planning*, never a shortcut to execution. Auto Mode does not override this.

Heuristic for the ID-vs-freeform classification: if the argument contains a space, a URL, an `@` file mention, a newline, or is longer than 40 characters, treat it as freeform. Otherwise try ID-pattern matching. When in doubt, prefer freeform — the worst case is an extra intake turn, not silent execution.

### `/story list` — list all stories

1. Read `docs/progress.md`
2. Display a formatted table of all stories: ID, Title, Status, Phase, Last Updated
3. Highlight any stories that are `active` or `executing`
4. Ask if the user wants to resume one or create a new story

### `/story status <id>` — detailed story status

1. Resolve story path from `docs/progress.md`
2. Read `story.md` and `acceptance-criteria.md`
3. Display detailed status:
   - Story ID, title, epic (if any)
   - Current phase, current task
   - Progress: X/Y tasks done, Z blocked
   - Acceptance criteria: X/Y passed
   - Last updated timestamp
   - Next action (what will happen if resumed)

### `/story` (no arguments) — same as list

1. Same behavior as `/story list`

---

## ID Resolution

Given an ID, resolve the story path:

1. Read `docs/progress.md`
2. Find the row where the ID column matches (case-insensitive)
3. Return the Path column value
4. If not found, return null

This is used by `resume`, `status`, and smart routing.

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
| Intake | story.md | CLAUDE.md, relevant source files |
| Planning | story.md | acceptance-criteria.md, source files |
| Task Generation | story.md, acceptance-criteria.md | — |
| Execution | story.md | Current task's relevant source files only |
| Verification | story.md, acceptance-criteria.md | Implemented source files |
| Closeout | All story files | — |

**Never load simultaneously:** Multiple stories' files. Focus on one story at a time.

---

## Sub-Agent Delegation Strategy

Use the Agent tool for parallel execution and to keep the main context clean:

| Activity | Delegate? | Why |
|----------|-----------|-----|
| Intake questions, planning | No | Requires accumulated user context |
| Task generation | No | Needs full plan context to be coherent |
| Parallel `[P]` tasks | Yes (one agent per task) | Only way to run tasks concurrently |
| Sequential tasks | Optional | Keeps implementation details out of main context |
| Verification | No | Needs full story context |
| Closeout | No | Needs full story context |

**Sub-agent context:** Each sub-agent receives its task definition, the implementer agent role, relevant file paths, and project conventions. It does NOT receive other tasks, chat history, or tracking files.

**Sub-agent result:** Each reports back: status (Complete/Blocked/Partial), files changed, issues encountered. The orchestrator uses this to update tracking docs.

---

## State Machine

The `current_phase` field in `story.md` YAML frontmatter is the canonical state:

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
1. Update `story.md` frontmatter (`current_phase`, `last_updated`)
2. Log the transition in the Phase History section of `story.md`
3. Update `docs/progress.md` Phase column

---

## story.md Structure

The `story.md` file is the single source of truth for each story. It combines what was previously spread across `plan.md`, `progress.md`, and `tasks.md`. Structure:

```markdown
---
id: "HRAB-7026"
id_source: external
title: "Global progress tracking"
status: active
epic: "HRAB-7000"
owner: "@enogueira"
current_phase: executing
current_task: T3
total_tasks: 8
completed_tasks: 4
blocked_tasks: 0
depends_on: []
created: "2026-04-15T10:30:00Z"
last_updated: "2026-04-15T14:32:00Z"
---

# [Title]

## Summary
[What the story is and why]

## Context
[Background and codebase context gathered during intake]

## Scope
[Bulleted list of what's included]

## Out of Scope
[What this story does NOT cover]

## Affected Pages / Modules
[Table of files/modules affected]

## Related Backend Contracts / APIs
[Table of API endpoints involved]

## Assumptions
[Things treated as true]

## Dependencies
[External dependencies]

## Risks
[What could go wrong]

## Implementation Strategy
[High-level approach — guides task generation]

## Tasks

### Execution Order
[Visual dependency diagram]

### T1: [Title]
- **Status:** done | todo | in_progress | blocked
- **Dependencies:** none | T1, T2
- **Parallelizable:** true | false
- **Description:** [What to do, where, how to verify]
- **Linked Criteria:** [Which acceptance criteria this implements]
- **Notes:** [Context, gotchas, patterns]

### T2: [Title]
...

## Phase History
| Phase | Entered | Exited | Notes |
|-------|---------|--------|-------|

## Current Status
[Free-form status notes, completed items, blockers, next steps]
```

---

## Resume Support

When resuming, follow [resume.md](references/resume.md):
1. Resolve story path from `docs/progress.md` using ID
2. Read `story.md`, `acceptance-criteria.md`, `decisions.md`
3. Parse `current_phase` from `story.md` frontmatter
4. Announce the current state to the user
5. Dispatch to the correct phase and continue

For execution phase resume: also parse `current_task` and task statuses from the Tasks section to find where to pick up.

---

## Error Handling

- **Story not found in progress.md:** Suggest `/story create --id <id>`
- **Corrupted story.md:** Reconstruct state from acceptance-criteria.md and decisions.md. Log decision.
- **Sub-agent failure:** Log the failure, mark task as blocked, continue with next available task
- **All tasks blocked:** Stop and report to user with diagnostics
- **Verification loop (gaps → execute → verify → gaps):** If this happens 3+ times, stop and report to user — something fundamental is wrong

---

## File Paths

**Story data (per-project, relative to project root):**
- Global index: `docs/progress.md`
- Standalone stories: `docs/stories/{story-id}-{slug}/`
- Epic stories: `epics/{epic-id}-{slug}/stories/{story-id}-{slug}/`
- Files per story: `story.md`, `acceptance-criteria.md`, `decisions.md`, `notes.md` (optional)

**Workflow infrastructure (bundled with plugin):**
- All references, agents, phases, and rules are in this skill's `references/` directory
- Templates are in `docs/stories/_template/` relative to the plugin root
- No project-level setup required
