# Core Workflow Rules

These rules govern all phases of the story workflow. They are non-negotiable.

## The 10 Rules

1. **Read before acting.** Always read all story documents (`story.md`, `acceptance-criteria.md`, `decisions.md`) before starting or resuming any work. The markdown files are your briefing — never operate from memory alone.

2. **Markdown is the source of truth.** The `story.md` file at the story's path (resolved from `docs/progress.md`) represents the canonical state of the story. If chat memory conflicts with what the markdown says, trust the markdown. Update the markdown to correct it — never silently diverge.

3. **No undefined work.** Never execute work that is not represented in `story.md` (in the plan sections or the Tasks section). If you discover something that needs doing, add it to the plan/tasks first, then execute. This ensures traceability and prevents scope creep.

4. **Autonomous after approval.** Once the user approves the plan (Phase 2 → Phase 3 transition), proceed through task generation, execution, verification, and closeout without asking permission for each task. The approval covers the entire approved scope.

5. **Update story.md immediately.** After every completed, blocked, or changed task, update the task status in the Tasks section and the frontmatter counters (`completed_tasks`, `blocked_tasks`). Never batch task status updates — a crash between updates would lose state.

6. **Update docs/progress.md after each batch.** After each meaningful execution batch (one task or one parallel group), update `docs/progress.md` with the current phase. Update `story.md` frontmatter with `current_task` and `last_updated`. Update the Current Status section in `story.md` with completed items, in-progress items, and next steps.

7. **Log decisions as they happen.** Update `decisions.md` whenever you make a relevant implementation decision — technology choice, pattern selection, trade-off resolution, deviation from common practice. Include the reason and alternatives considered.

8. **Replan before continuing.** If execution reveals new required work, a scope change, or a conflict with the plan — stop executing, update the plan sections and Tasks section in `story.md` to reflect the new reality, then continue. Never silently change scope.

9. **Stop only when necessary.** The only valid reasons to stop autonomous execution are:
   - Unresolved ambiguity that changes user-visible behavior
   - Missing file access or missing external resources
   - Repeated technical failure (same error 3+ times)
   - Conflict between what you're implementing and the approved plan
   
   Everything else — including minor uncertainties, implementation details, and recoverable errors — should be handled by making a decision (logged in `decisions.md`) and continuing.

10. **Continue until done.** Keep executing until all tasks in the Tasks section of `story.md` are marked `done`, all acceptance criteria are verified, and the closeout summary is written. Do not stop early. Do not ask "should I continue?" — the approved plan is your authorization.

## When Rules Conflict

If a situation creates tension between rules (e.g., rule 3 says "no undefined work" but rule 10 says "continue until done"), resolve by:
1. Update the plan/tasks in `story.md` first (satisfying rule 3)
2. Then continue (satisfying rule 10)
3. Log the decision in `decisions.md` (satisfying rule 7)
