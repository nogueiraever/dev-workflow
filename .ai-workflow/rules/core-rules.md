# Core Workflow Rules

These rules govern all phases of the autonomous feature workflow. They are non-negotiable and must be followed by every agent and prompt in the system.

---

## Rule 1: Read Before Acting

Always read all feature documents before starting or resuming work:
- `plan.md` — the approved scope and strategy
- `tasks.md` — current task breakdown and statuses
- `acceptance-criteria.md` — what "done" looks like
- `progress.md` — current phase and state
- `decisions.md` — past decisions for context

Never operate from memory alone. The files are your briefing.

## Rule 2: Markdown Is the Source of Truth

The files in `docs/features/<name>/` represent the canonical state of the feature. If chat memory conflicts with what the markdown says, trust the markdown. Update the markdown to correct it — never silently diverge.

## Rule 3: No Undefined Work

Never execute work that is not represented in `plan.md` or `tasks.md`. If you discover something that needs doing:
1. Add it to the plan and/or tasks first
2. Then execute it

This ensures traceability and prevents scope creep.

## Rule 4: Autonomous After Approval

Once the user approves the plan (Phase 2 → Phase 3 transition), proceed through task generation, execution, verification, and closeout without asking permission for each task. The approval covers the entire approved scope.

## Rule 5: Update tasks.md Immediately

After every completed, blocked, or changed task, update `tasks.md`:
- Change the task status
- Update the frontmatter counters (`completed`, `blocked`)
- Never batch status updates — a crash between updates would lose state

## Rule 6: Update progress.md After Each Batch

After each meaningful execution batch (one task or one parallel group):
- Update current status section
- Update completed/in-progress/blocked items
- Update `current_task` in frontmatter
- Update `last_updated` timestamp

## Rule 7: Log Decisions As They Happen

Update `decisions.md` whenever you make a relevant implementation decision:
- Technology or library choice
- Pattern selection
- Trade-off resolution
- Deviation from common practice

Include: the decision, the reason, alternatives considered, and impact.

## Rule 8: Replan Before Continuing

If execution reveals:
- New required work
- A scope change
- A conflict with the approved plan

Then: stop executing → update `plan.md` and `tasks.md` → log the change in `decisions.md` → resume execution. Never silently change scope.

## Rule 9: Stop Only When Necessary

The only valid reasons to stop autonomous execution are:
- **Unresolved ambiguity** that changes user-visible behavior
- **Missing access** — files, services, or resources you cannot reach
- **Repeated technical failure** — same error 3+ times after different approaches
- **Plan conflict** — what you're building contradicts the approved plan

Everything else — minor uncertainties, implementation details, recoverable errors — should be handled by making a decision (logged in `decisions.md`) and continuing.

## Rule 10: Continue Until Done

Keep executing until:
- All tasks in `tasks.md` are marked `done`
- All acceptance criteria are verified
- The closeout summary is written

Do not stop early. Do not ask "should I continue?" The approved plan is your authorization.

---

## When Rules Conflict

If a situation creates tension between rules (e.g., rule 3 says "no undefined work" but rule 10 says "continue until done"):
1. Update the plan/tasks first (satisfying rule 3)
2. Then continue (satisfying rule 10)
3. Log the decision (satisfying rule 7)
