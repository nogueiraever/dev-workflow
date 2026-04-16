---
name: story-init
description: "Manual entrypoint: run only the intake and planning phases for a story. Resolves story by ID from docs/progress.md, gathers requirements, generates plan and acceptance criteria in story.md, and presents for approval. Does NOT proceed to task generation or execution. Use when you want to plan a story without starting implementation."
argument-hint: "<id> [--epic EPIC] [--title \"...\"]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# Story Init (Manual Entrypoint)

This runs only Phases 1-2 of the story workflow: Intake and Planning.

## Process

### 1. Parse Arguments

Parse `$ARGUMENTS` for:
- **ID** (required): The first positional argument. Can be an external ticket ID (e.g., `HRAB-7026`) or an internal ID (e.g., `S1`). If empty, ask for one.
- **`--epic <EPIC-ID>`** (optional): Parent epic ID. Determines directory placement under `docs/epics/`.
- **`--title <TITLE>`** (optional): Story title. If omitted, will be gathered during intake.

### 2. Resolve or Create Story

**Check `docs/progress.md` for existing story:**

Read `docs/progress.md` and search the ID column for a row matching the provided ID (case-insensitive).

**If story exists:**
- Extract the Path column value to get the story directory
- Read `story.md` to check `current_phase` in frontmatter
- If already past planning (`task_generation`, `executing`, `verifying`, `closeout`, `complete`), warn the user and suggest `/story resume <id>` instead
- If in `intake` or `planning` or `pending_approval` or `revising`, continue from current state

**If story does not exist:**
1. **Determine `id_source`:**
   - If the ID matches pattern `S<number>` → `id_source: internal`
   - Otherwise → `id_source: external`

2. **Generate slug** from the title (if provided):
   - Lowercase the title
   - Replace spaces with hyphens
   - Strip special characters (keep alphanumeric and hyphens only)
   - Truncate to max 50 characters
   - If no title provided yet, use the ID as a temporary slug

3. **Determine story path:**
   - If `--epic` provided: `docs/epics/{epic-id}-{epic-slug}/stories/{story-id}-{slug}/`
   - If no `--epic`: `docs/stories/{story-id}-{slug}/`

4. **Create story directory and files:**
   - Locate templates: check `docs/stories/_template/` in project root, then `~/.dev-workflow/templates/`
   - Create the story directory
   - Create `story.md` with frontmatter:
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

5. **Register in global index:**
   - Add a row to `docs/progress.md` with: ID, Title, Status (`active`), Phase (`intake`), Path, Created, Last Updated
   - If `docs/progress.md` doesn't exist, create it with the table header:
     ```markdown
     # Progress

     | ID | Title | Status | Phase | Path | Created | Last Updated |
     |----|-------|--------|-------|------|---------|--------------|
     ```

### 3. Run Phase 1: Intake

Follow the process in the story skill's [phase-intake.md](../story/references/phase-intake.md):
- Parse the user's story request
- Explore the codebase for context
- Ask clarifying questions if needed
- Write initial notes to the Summary, Context, and Assumptions sections of `story.md`

**Transition:** Update `story.md` frontmatter:
- Set `current_phase: planning`
- Update `last_updated`
- Log the phase transition in the Phase History table of `story.md`
- Update `docs/progress.md` Phase column

### 4. Run Phase 2: Planning

Follow the process in the story skill's [phase-planning.md](../story/references/phase-planning.md):
- Generate complete plan sections in `story.md` (Summary, Scope, Out of Scope, Affected Pages/Modules, Related Backend Contracts/APIs, Assumptions, Dependencies, Risks, Implementation Strategy)
- Generate `acceptance-criteria.md`
- Update `story.md` frontmatter: `current_phase: pending_approval`
- Update `docs/progress.md` Phase column
- Log the transition in Phase History
- Present plan to user for review

### 5. Stop

After presenting the plan, **stop here**. Do not proceed to task generation.

**If user approves:**
- Update `story.md` frontmatter: `current_phase: pending_approval` stays (or transitions to `task_generation` if approved in this session)
- Suggest: `/story resume <id>` or `/story-tasks <id>` to proceed to task generation

**If user requests changes:**
- Update `story.md` frontmatter: `current_phase: revising`
- Apply changes to `story.md` plan sections and/or `acceptance-criteria.md`
- Log what changed in `decisions.md`
- Re-present the updated plan
- When re-approved, update `story.md` frontmatter: `current_phase: pending_approval`

After the plan is presented and the user responds (approved or changes applied), **stop**. Do not proceed to task generation even if approved.

Suggest next steps:
- `/story resume <id>` to pick up from task generation (runs the full remaining workflow)
- `/story-tasks <id>` to generate tasks only (manual control)

## Error Handling

- **ID not provided:** Ask the user for a story ID
- **Story exists but past planning:** Warn and suggest `/story resume <id>`
- **`docs/progress.md` missing:** Create it with headers when registering the new story
- **Epic directory doesn't exist:** Create it when creating the story path
- **Template files not found:** Create minimal story.md, acceptance-criteria.md, and decisions.md with standard structure

## Rules

Follow [rules.md](../story/references/rules.md) for all tracking and markdown updates.

All state transitions must:
1. Update `story.md` frontmatter (`current_phase`, `last_updated`)
2. Log the transition in the Phase History section of `story.md`
3. Update `docs/progress.md` Phase column
