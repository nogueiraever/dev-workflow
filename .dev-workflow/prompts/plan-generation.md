# Plan Generation Prompt

You are executing Phase 2 of the autonomous story workflow. Intake is complete. You now have enough context to produce the full plan.

## Context

Read the current state of:
- `story.md` — has initial notes from intake in the Summary, Affected Pages/Modules, and Assumptions sections; frontmatter should show `current_phase: planning`

## Instructions

### Step 1: Generate plan sections in story.md

Fill in every section completely:

**Summary** — One paragraph: what this story does and why it exists.

**Scope** — Specific bulleted list of what's included. Be precise: "Add download button to employee notes panel" not "UI changes."

**Out of Scope** — What this story does NOT cover. Prevents scope creep during execution.

**Affected Pages / Modules** — Table: area, type (frontend/backend/infra), impact description.

**Related Backend Contracts / APIs** — Table: endpoint, method, change type (new/modified/consumed).

**Assumptions** — Things treated as true that could invalidate the plan if wrong.

**Dependencies** — External dependencies with type and status (available/pending/unknown).

**Risks** — Each risk with likelihood, impact, and mitigation.

**Implementation Strategy** — High-level approach, phase breakdown, technical notes.

All of these are sections within `story.md`, below the frontmatter.

### Step 2: Generate acceptance-criteria.md

For each scope item, write testable criteria:

**User-Visible Behavior** — Format: "When [action], then [expected result]."
**Validations** — Input validation, business rules, authorization checks.
**Formatting Expectations** — UI layout, date formats, responsive behavior.
**Edge Cases** — Empty states, error states, boundary values, permissions.
**Success Conditions** — Overall "done" checklist.

Give each criterion a unique ID (AC1, V1, F1, E1).

### Step 3: Present for Approval

Update `story.md` frontmatter: `status: pending_approval`, `current_phase: pending_approval`
Log the phase transition in the Phase History table in `story.md`.

Present the plan summary to the user and wait for their response:
- If approved → transition to `task_generation`
- If changes requested → set `current_phase: revising`, make changes, re-present

## Output

- Completed plan sections in `story.md`
- Completed `acceptance-criteria.md` with testable criteria
- Updated `story.md` frontmatter with phase transition
- Plan presented to user for approval
