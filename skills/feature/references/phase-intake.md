# Phase 1: Intake

**Status value:** `intake`
**Agent:** [planner](agents/planner.md)

## Objective

Gather enough understanding of the feature request to produce a complete plan. Ask clarifying questions only when truly needed — most features can be understood from the request + codebase exploration.

## Process

### 1. Parse the Feature Request

Read the user's feature request carefully. Extract:
- What they want built (the WHAT)
- Why they want it (the WHY, if stated)
- Any constraints they mentioned (technology, timeline, compatibility)
- Any specific files, pages, or modules they referenced

### 2. Explore the Codebase

Before asking questions, explore the codebase to answer your own questions:
- Read CLAUDE.md files for project context and conventions
- Find the files/modules the feature would touch
- Understand existing patterns in the affected area
- Check for existing similar functionality that could be extended
- Identify the API contracts / data models involved

### 3. Identify Gaps

After exploration, identify what you still don't know:
- Ambiguous behavior (two valid interpretations)
- Missing context (which of several possible approaches does the user prefer?)
- External dependencies (APIs, services, data sources you can't verify)
- Business rules that aren't in the code

### 4. Ask Clarifying Questions (Only If Needed)

If gaps exist that would materially change the plan:
- Ask all questions at once (don't drip-feed them)
- For each question, explain why it matters and offer your default assumption
- If a question has an obvious answer from the codebase, don't ask — just note it as an assumption

If no gaps exist, skip this step entirely.

### 5. Write Initial Notes

Update `plan.md` with:
- The Summary section (what the feature is)
- Initial notes in Affected Pages/Modules (from codebase exploration)
- Initial notes in Assumptions (what you're assuming)

### 6. Transition

Update `progress.md`:
- Set `current_phase: planning`
- Log the phase transition in the Phase History table
- Update `last_updated`

Proceed immediately to Phase 2 (Planning).

## Exit Criteria

- You understand what the feature does and why
- You've explored the relevant codebase
- Any critical ambiguities have been resolved with the user
- `plan.md` has initial notes
- `progress.md` shows `current_phase: planning`
