# Phase 2: Planning

**Status values:** `planning` → `pending_approval` (→ `revising` if changes requested)
**Agent:** [planner](agents/planner.md)

## Objective

Produce a complete plan and acceptance criteria that the user can approve. This is the last human checkpoint — after approval, execution is autonomous.

## Process

### 1. Fill story.md Plan Sections

Fill in every plan section of `story.md`:

**Summary** — One paragraph describing what this story does and why.

**Scope** — Bulleted list of what's included. Be specific: "Add download button to employee notes panel" not "UI changes."

**Out of Scope** — Explicitly list what this story does NOT cover. This prevents scope creep during execution.

**Affected Pages / Modules** — Table of every file, page, component, service, or module that will be created or modified. Include the type (frontend/backend/infra) and the nature of the change.

**Related Backend Contracts / APIs** — Table of every API endpoint or data contract involved. Include method, whether it's new or existing, and what changes.

**Assumptions** — Things you're treating as true that could invalidate the plan if wrong. Every assumption from intake belongs here.

**Dependencies** — External dependencies: packages, services, APIs, data, other stories. Include their status (available/pending/unknown).

**Risks** — What could go wrong? Include likelihood, impact, and mitigation for each.

**Implementation Strategy** — High-level approach. Describe the phases of implementation, key technical decisions, and patterns to follow. This guides task generation.

### 2. Generate acceptance-criteria.md

For each scope item, write testable criteria:

**User-Visible Behavior** — What the user sees/does. Format: "When [action], then [expected result]."

**Validations** — Input validation, business rules, authorization checks.

**Formatting Expectations** — UI layout, date formats, number formats, responsive behavior.

**Edge Cases** — Empty states, error states, boundary values, concurrent access, permission boundaries.

**Success Conditions** — The overall checklist that defines "done."

### 3. Set Status and Present

Update `story.md` frontmatter:
- `status: active`
- `current_phase: pending_approval`
- `last_updated: <now>`

Log the transition in the Phase History section.

Update `docs/progress.md` Phase column for this story.

Print a short plan summary to chat so the user has context alongside the approval prompt:

```
## Plan Ready for Review

Story [id]: [title]

**What:** [one sentence]
**Scope:** [key items]
**Tasks will cover:** [high-level areas]
**Risks:** [top risks]

Full plan: {story-path}/story.md
Acceptance criteria: {story-path}/acceptance-criteria.md
```

Then **request approval with the `AskUserQuestion` tool** (not with a prose prompt):

- Question: `Approve the plan for story [id]?`
- Header: `Plan approval`
- Options:
  1. `Approve` — "Generate tasks and begin autonomous execution."
  2. `Request changes` — "Describe the changes in the free-form answer; I'll revise and re-present."
  3. `Abort` — "Leave the story in pending_approval and stop."

The `AskUserQuestion` tool forces a user turn. Do **not** call any other tool in the same message as the approval prompt, and do **not** continue to Phase 3 until the tool returns with the user's selection.

#### Auto-Mode Exception (non-negotiable)

This approval gate **MUST NOT** be bypassed even when the session has Auto Mode active or any other "be more autonomous" directive is in force. Plan approval is never a "routine decision" — it is a hard human checkpoint. The model does not have authority to self-approve on the user's behalf. If you find yourself reasoning "auto mode says minimize interruptions, so I'll assume approval," stop: that reasoning is wrong for this gate. See [rules.md](rules.md) Rule 11.

### 4. Handle User Response

Read the answer returned by `AskUserQuestion`:

**If the user chose `Approve` (or "Other" with clearly affirmative text like "approved" / "looks good" / "go ahead"):**
- Update `story.md` frontmatter: `current_phase: task_generation`
- Update `last_updated`
- Log transition in Phase History section
- Update `docs/progress.md` Phase column
- Proceed immediately to Phase 3 (Task Generation)

**If the user chose `Request changes` (or "Other" with change instructions):**
- Update `story.md` frontmatter: `current_phase: revising`
- Apply the requested changes to `story.md` plan sections and/or `acceptance-criteria.md`
- Log what changed in `decisions.md`
- Return to step 3 (re-present the updated plan via `AskUserQuestion`)

**If the user chose `Abort`:**
- Leave `story.md` frontmatter at `current_phase: pending_approval`
- Log the abort in the Phase History section with a note
- Stop. Do not enter Phase 3.

## Exit Criteria

- `story.md` plan sections are complete and thorough
- `story.md` frontmatter shows `current_phase: task_generation`
- `acceptance-criteria.md` has testable criteria for all scope items
- `docs/progress.md` reflects the phase transition
- User has explicitly approved
