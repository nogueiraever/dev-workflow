---
name: task
description: "Add a small scoped adjustment to the currently in-progress story. Runs planner for the adjustment using current story context and waits for approval before execution. Use during story execution for minor follow-up changes that do not justify a new story."
argument-hint: "[--story <id>] <request>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Agent
---

# Story-Scoped Task Adjustment Workflow

Use this command when the user asks for a **minor additional change** while a story is already in progress.

`/task` does **not** create a new story. It appends scoped work to the current story, replans that adjustment, and gates execution behind approval.

## Argument Parsing

Parse `$ARGUMENTS`:

- `--story <id>` (optional): explicit target story
- Remaining text: required adjustment request

If no request text is provided, ask the user to describe the adjustment.

## 1) Resolve Target Story

### If `--story <id>` is provided
1. Resolve the story path from `docs/progress.md` by matching ID.
2. If not found, show: story not found and suggest `/story list`.

### If `--story` is omitted
1. Read `docs/progress.md` and identify candidate stories with:
   - Status: `active` or `executing`
   - Phase: `task_generation`, `executing`, or `verifying`
2. Resolution rules:
   - Exactly 1 candidate → use it.
   - 0 candidates → fail with guidance: `/task` requires an in-progress story. Suggest `/story list` or `/story resume <id>`.
   - >1 candidates → ask user to disambiguate with `--story <id>`.

## 2) Validate Preconditions

Read `<story-path>/story.md` and validate:

- Allowed current phases for `/task`: `task_generation`, `executing`, `verifying`
- Disallowed phases: `intake`, `planning`, `pending_approval`, `revising`, `closeout`, `complete`

If disallowed, explain why and suggest `/story resume <id>`.

If `current_phase` is already `pending_approval` or `revising`, do not start a second adjustment plan. Ask the user to resolve the existing approval first.

## 3) Plan the Adjustment (Story-Aware)

Run the planner behavior (same standards as story planning), but scoped to an incremental change.

Planner input must include:
1. User adjustment request (verbatim)
2. Current story context from `story.md`:
   - Summary
   - Scope / Out of Scope
   - Implementation Strategy
   - Existing Tasks section
   - Current phase and progress counters
3. Acceptance criteria from `acceptance-criteria.md`
4. Explicit instruction:
   - "Plan an incremental adjustment for the current story. Do not create a new story. Update existing plan/tasks only as needed to include this request."

Planner output updates:
- `story.md`:
  - Append/update plan details needed for the adjustment
  - Add or update tasks required for the adjustment (with dependencies)
  - Update counters (`total_tasks`, `completed_tasks`, `blocked_tasks`) to match tasks
  - Set `current_phase: pending_approval`
  - Set `last_updated`
  - Append Phase History entry: `executing|verifying|task_generation -> pending_approval` with note `task-adjustment`
- `acceptance-criteria.md`:
  - Add/adjust criteria only when needed for the new adjustment
- `docs/progress.md`:
  - Update the story phase to `pending_approval`

## 4) Present Plan and Wait for Approval

Present a concise summary:
- What was added/changed
- New or changed tasks
- Any risk/tradeoff

Then stop and wait for explicit approval.

**Do not execute any task adjustments before approval.**

## 5) After Approval (Execution Resume)

When approved:
1. Transition back to execution flow:
   - `current_phase: task_generation` only if task graph had to be regenerated from scratch
   - otherwise `current_phase: executing`
2. Update Phase History and `docs/progress.md`
3. Continue execution from dependency-ready tasks, including new adjustment tasks.

## Behavior Notes

- `/task` is for small in-story scope changes, not net-new initiatives.
- If requested adjustment materially changes goals or introduces broad scope, recommend creating a new story instead.
- Never execute undefined work: ensure every new change is reflected in `story.md` tasks first.

## Error Handling

- **No in-progress story found:** explain requirement and suggest `/story list`
- **Multiple in-progress stories:** require `--story <id>`
- **Story in approval phase already:** request resolving current approval before creating another adjustment
- **Adjustment too broad:** recommend new `/story create`
