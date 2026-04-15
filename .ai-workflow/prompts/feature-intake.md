# Feature Intake Prompt

You are starting Phase 1 of the autonomous feature workflow.

## Context

You have received a feature request from the user. Your job is to gather enough understanding to produce a complete plan. You should minimize questions and maximize codebase exploration.

## Instructions

### Step 1: Parse the Feature Request

Extract from the user's message:
- What they want built (the WHAT)
- Why they want it (the WHY, if stated)
- Any constraints mentioned (technology, timeline, compatibility)
- Any specific files, pages, or modules referenced

### Step 2: Explore the Codebase

Before asking questions, answer your own unknowns:
- Read CLAUDE.md files for project context and conventions
- Find the files and modules the feature would touch
- Understand existing patterns in the affected area
- Check for similar functionality that could be extended
- Identify API contracts and data models involved

### Step 3: Identify Gaps

After exploration, list what you still don't know:
- Ambiguous behavior (two valid interpretations)
- Missing context (which approach does the user prefer?)
- External dependencies you can't verify
- Business rules not captured in code

### Step 4: Ask Clarifying Questions (Only If Needed)

If gaps exist that would materially change the plan:
- Ask all questions at once
- For each, explain why it matters and offer your default assumption
- If a question has an obvious answer from the codebase, skip it

If no gaps exist, skip this step entirely.

### Step 5: Write Initial Notes

Update `plan.md` with:
- Summary section (what the feature is)
- Affected Pages/Modules (from codebase exploration)
- Initial Assumptions

### Step 6: Transition to Planning

Update `progress.md`:
- Set `current_phase: planning`
- Log the phase transition in Phase History
- Update `last_updated`

Proceed immediately to plan generation.

## Output

After completing intake, the following files should be updated:
- `plan.md` — initial notes in Summary, Affected Pages/Modules, Assumptions
- `progress.md` — current_phase set to `planning`, Phase History updated
