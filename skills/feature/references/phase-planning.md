# Phase 2: Planning

**Status values:** `planning` → `pending_approval` (→ `revising` if changes requested)
**Agent:** [planner](agents/planner.md)

## Objective

Produce a complete plan and acceptance criteria that the user can approve. This is the last human checkpoint — after approval, execution is autonomous.

## Process

### 1. Generate plan.md

Fill in every section of `plan.md`:

**Summary** — One paragraph describing what this feature does and why.

**Scope** — Bulleted list of what's included. Be specific: "Add download button to employee notes panel" not "UI changes."

**Out of Scope** — Explicitly list what this feature does NOT cover. This prevents scope creep during execution.

**Affected Pages / Modules** — Table of every file, page, component, service, or module that will be created or modified. Include the type (frontend/backend/infra) and the nature of the change.

**Related Backend Contracts / APIs** — Table of every API endpoint or data contract involved. Include method, whether it's new or existing, and what changes.

**Assumptions** — Things you're treating as true that could invalidate the plan if wrong. Every assumption from intake belongs here.

**Dependencies** — External dependencies: packages, services, APIs, data, other features. Include their status (available/pending/unknown).

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

Update `plan.md` frontmatter: `status: pending_approval`
Update `progress.md` frontmatter: `current_phase: pending_approval`
Log the transition in Phase History.

Present the plan to the user:

```
## Plan Ready for Review

I've created the plan for [feature-name]. Here's a summary:

**What:** [one sentence]
**Scope:** [key items]
**Tasks will cover:** [high-level areas]
**Risks:** [top risks]

Full plan: docs/features/<name>/plan.md
Acceptance criteria: docs/features/<name>/acceptance-criteria.md

Please review and respond with:
- "approved" / "looks good" / "go ahead" → I'll generate tasks and begin autonomous execution
- Your requested changes → I'll update the plan and re-present
```

**STOP HERE AND WAIT FOR USER RESPONSE.**

### 4. Handle User Response

**If approved:**
- Update `plan.md` frontmatter: `status: approved`
- Update `progress.md`: `current_phase: task_generation`
- Log transition in Phase History
- Proceed immediately to Phase 3 (Task Generation)

**If changes requested:**
- Update `progress.md`: `current_phase: revising`
- Apply the requested changes to `plan.md` and/or `acceptance-criteria.md`
- Log what changed in `decisions.md`
- Return to step 3 (re-present the updated plan)

## Exit Criteria

- `plan.md` status is `approved`
- `acceptance-criteria.md` has testable criteria for all scope items
- `progress.md` shows `current_phase: task_generation`
- User has explicitly approved
