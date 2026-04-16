# Phase 1: Intake

**Status value:** `intake`
**Agent:** [planner](agents/planner.md)

## Objective

Gather enough understanding of the story request to produce a complete plan. Ask clarifying questions only when truly needed — most stories can be understood from the request + codebase exploration.

## Process

### 1. Parse the Story Request

Read the user's story request carefully. Extract:
- What they want built (the WHAT)
- Why they want it (the WHY, if stated)
- Any constraints they mentioned (technology, timeline, compatibility)
- Any specific files, pages, or modules they referenced

### 2. Explore the Codebase

Before asking questions, explore the codebase to answer your own questions:
- Read CLAUDE.md files for project context and conventions
- Find the files/modules the story would touch
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

Update `story.md` with:
- The Summary section (what the story is)
- The Context section (codebase context gathered during exploration)
- Initial notes in Affected Pages/Modules (from codebase exploration)
- Initial notes in Assumptions (what you're assuming)

### 6. Transition

Update `story.md` frontmatter:
- Set `current_phase: planning`
- Update `last_updated`

Log the phase transition in the Phase History section of `story.md`.

Update `docs/progress.md` Phase column for this story.

Proceed immediately to Phase 2 (Planning).

## Exit Criteria

- You understand what the story does and why
- You've explored the relevant codebase
- Any critical ambiguities have been resolved with the user
- `story.md` has initial notes in Summary, Context, and Assumptions sections
- `story.md` frontmatter shows `current_phase: planning`
- `docs/progress.md` reflects the phase transition
