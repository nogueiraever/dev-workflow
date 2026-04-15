You are an expert AI workflow architect.

Your task is to build a complete autonomous feature workflow inside this repository.

This workflow must be designed for Claude Code and must support:

- long-running feature work
- resumability across chats
- persistent markdown tracking inside the repo
- plan approval before execution
- autonomous task generation and execution after approval
- parallel execution where safe
- sequential execution where required
- continuous markdown updates during the entire lifecycle

The workflow must NOT require the user to manually trigger each step.
The normal mode must be a single orchestrated flow.

Optional manual commands may exist for advanced use, but they are secondary.

## Primary goal

Create a repo-local workflow that behaves like this:

1. Start a feature from a high-level request
2. Ask clarifying questions when needed
3. Build a plan
4. Save the plan in markdown
5. Present the plan to the user for approval
6. If the user requests changes, update the markdown and re-present it
7. Once approved, automatically:
   - generate tasks
   - classify dependencies
   - classify parallel vs sequential work
   - execute tasks
   - update tracking docs continuously
   - replan if needed
   - validate completion
8. End with a final implementation summary

## Create this folder structure

/docs/features/_template/
/docs/features/

/.ai-workflow/
  orchestrators/
  prompts/
  agents/
  rules/

## Create these feature files in /docs/features/_template/

### plan.md
Must include:
- feature summary
- scope
- out of scope
- affected pages/modules
- related backend contracts/APIs
- assumptions
- dependencies
- risks
- implementation strategy

### tasks.md
Must include tasks in structured format with:
- id
- title
- description
- status: todo | in_progress | blocked | done
- dependency_ids
- parallelizable: true/false
- linked_plan_items
- notes

### acceptance-criteria.md
Must include:
- user-visible behavior
- validations
- formatting expectations
- edge cases
- success conditions

### progress.md
Must include:
- current status
- completed items
- in-progress items
- blocked items
- next recommended steps

### decisions.md
Must include:
- decision
- reason
- alternatives considered
- impact

## Create workflow rules

Create:
/.ai-workflow/rules/core-rules.md

Rules must include:

- Always read all feature documents before starting or resuming work
- The markdown files are the source of truth, not chat memory
- Never execute undefined work unless first added to the plan/tasks
- After plan approval, continue autonomously without asking permission for each task
- Update tasks.md after every completed, blocked, or changed task
- Update progress.md after each meaningful execution batch
- Update decisions.md whenever a relevant implementation decision is made
- If new discoveries require scope adjustment, update plan.md and tasks.md before continuing
- Stop only for:
  - unresolved ambiguity that changes behavior
  - missing access or missing files
  - repeated technical failure
  - conflict between implementation and approved plan
- Otherwise continue until all accepted tasks are finished

## Create internal prompts

Create these files under /ai-workflow/prompts/:

- feature-intake.md
- plan-generation.md
- task-generation.md
- execution-engine.md
- verification.md
- resume-feature.md

These are internal building blocks for the autonomous workflow.
They are not the primary interface.

## Create subagents

Create these files under /ai-workflow/agents/:

### planner.md
Responsible for:
- clarifying scope
- creating and updating the plan
- aligning plan with acceptance criteria

### task-breaker.md
Responsible for:
- converting plan into concrete tasks
- defining dependencies
- marking tasks as parallelizable or sequential

### implementer.md
Responsible for:
- executing tasks
- following existing code patterns
- minimizing regressions

### reviewer.md
Responsible for:
- checking whether implemented work matches task intent
- checking for missed requirements
- identifying incomplete work

### verifier.md
Responsible for:
- validating implementation against acceptance criteria and plan
- identifying gaps before completion

### tracker.md
Responsible for:
- updating tasks.md, progress.md and decisions.md
- keeping markdown state consistent with actual implementation

For each agent, include:
- role
- responsibilities
- strict rules
- expected inputs
- expected outputs

## Create the autonomous orchestrator

Create:
/.ai-workflow/orchestrators/feature-orchestrator.md

This is the main workflow entrypoint.

It must work like this:

### Phase 1 — Intake
- gather the initial feature request
- ask clarifying questions only if necessary
- identify affected areas, constraints, contracts, risks

### Phase 2 — Planning
- generate plan.md
- generate acceptance-criteria.md
- present plan to the user
- wait for approval or requested edits
- if changes are requested, update markdown and repeat

### Phase 3 — Task generation
After approval, automatically:
- generate tasks.md
- map dependencies
- decide parallel vs sequential execution

### Phase 4 — Execution
After tasks are generated, automatically:
- begin executing tasks without asking permission one by one
- use parallel execution only when tasks are independent
- use sequential execution when dependencies exist
- update markdown continuously
- if implementation reveals new required work, update plan/tasks first, then continue

### Phase 5 — Verification
- verify against acceptance-criteria.md
- verify all tasks are truly complete
- verify no obvious gaps remain
- if gaps exist, generate follow-up tasks and continue automatically when safe

### Phase 6 — Closeout
- produce final summary
- list what was completed
- list any remaining blockers or optional follow-ups

## Create optional manual entrypoints

Also create optional manual prompts for advanced use:
- init-only
- generate-tasks-only
- execute-only
- verify-only
These are fallback/manual tools only.

## Resume support

Create resume instructions such that in a new chat the workflow can continue by:

1. reading all files under /docs/features/<feature-name>/
2. determining the current state from tasks.md and progress.md
3. continuing execution from the first valid remaining task
4. updating markdown as work progresses

## Usage requirements

After generating everything, provide:
- the created folder structure
- the primary usage command/prompt for starting a feature
- the primary usage command/prompt for resuming a feature
- the optional manual commands
- a short explanation of how autonomous execution works

Important:
- the primary path must be autonomous
- manual per-step execution is optional only
- build all files completely, not as stubs