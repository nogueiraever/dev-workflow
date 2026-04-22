---
name: epic
description: "Manage epics — large initiatives that group related stories. Create, list, resume, and track epics with linked story status. When creating with a Jira ID, automatically imports child stories from Jira, plans every story in parallel, and — after a single approval prompt — autonomously generates tasks and starts coding. Use: /epic create, /epic plan, /epic list, /epic <id>, /epic status <id>, /epic resume <id>."
argument-hint: "[create [--id ID] [--title TITLE] [--no-import] [--no-plan] | plan <id> | list | status <id> | resume <id> | <id> | <freeform description>]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
  - AskUserQuestion
  - mcp__claude_ai_Atlassian__getAccessibleAtlassianResources
  - mcp__claude_ai_Atlassian__getJiraIssue
  - mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql
---

# Epic Management

## Hard Contract (read before anything else)

When the user invokes `/epic` — with ANY argument, in ANY phrasing — you **must** route through this skill and end up with an epic tracked in markdown (`epic.md` + `docs/progress.md`). This is a non-negotiable contract.

- You do **not** have discretion to decide "this looks like a different kind of task, I'll just do it directly without creating an epic." Every `/epic` invocation produces or resumes an epic. Period.
- If the user's request seems like research, audit, or synthesis work, that is still epic-scoped work — it becomes the epic's **Summary / Goals / Scope**, and the child stories under it carry the actual tasks.
- The ONLY valid outcomes of an `/epic` invocation are: (a) a new epic is created, (b) an existing epic resumes via the Resume Flow, or (c) a help/list block is printed for `/epic list` / `/epic status <id>`. "I decided to just do the task directly" is NOT a valid outcome.
- This contract exists because the entire value of this workflow is persistent progress tracking via markdown. If you bypass epic/story creation, the user loses their progress record. Do not do that.

```
 ┌──────────┐        ┌───────────────┐        ┌───────────────┐
 │  CREATE   │  ───>  │    ACTIVE      │  ───>  │   COMPLETE    │
 │  (draft)  │        │ stories added  │        │ all stories   │
 └──────────┘        │ work in flight │        │ done          │
                      └───────────────┘        └───────────────┘
                        │         ▲
                        ▼         │
                      ┌───────────────┐
                      │   BLOCKED     │
                      └───────────────┘
```

Epics are lightweight containers — no phase state machine. Status is managed manually with workflow suggestions.

**Status vocabulary:** `draft` | `active` | `blocked` | `complete` | `archived`

---

## Argument Parsing

Parse `$ARGUMENTS` to determine the subcommand:

### `/epic create [--id ID] [--title "TITLE"] [--no-import] [--no-plan]` — create a new epic
1. Parse flags:
   - `--id` for external ID (e.g., Jira epic key like `HRAB-7000`)
   - `--title` for epic title
   - `--no-import` to skip fetching stories from Jira
   - `--no-plan` to skip planning imported stories (just scaffold directories)
2. If `--title` is missing and `--id` is external, the title may be fetched from Jira during import
3. If `--title` is still missing after import, ask the user for a title
4. Follow the **Create Flow** below

### `/epic plan <id>` — plan all unplanned stories in an epic
1. Resolve `<id>` to an epic path via **ID Resolution**
2. Follow the **Plan Flow** below

### `/epic list` — list all epics
1. Follow the **List Flow** below

### `/epic status <id>` — detailed epic status
1. Resolve `<id>` to an epic path via **ID Resolution**
2. Follow the **Status Flow** below

### `/epic resume <id>` — resume an epic (show status, offer actions)
1. Resolve `<id>` to an epic path via **ID Resolution**
2. Follow the **Resume Flow** below

### `/epic <arg>` — smart routing (resume, create-by-id, or create-from-description)
1. Classify the argument:
   - **ID pattern** — matches `E<number>` or contains a hyphen with letters+numbers (e.g., `HRAB-8730`, `PLAT-12`). Short, no spaces, no URLs, no sentence-style text.
   - **Freeform description** — anything else: a phrase, sentence, paragraph, or text containing spaces, URLs, `@path/` mentions, or file references. Treat as "the user is asking to create a new epic, and this text is the seed context."

2. **If ID pattern:** attempt **ID Resolution** for the argument.
   - **Found** → follow the **Resume Flow**.
   - **Not found** → ask the user: "No epic with ID `<id>` exists locally. Would you like to create it with `/epic create --id <id>`?" Then stop. Do not create automatically.

3. **If freeform description:** route to **Create Flow** with these seeds:
   - No `--id` provided → generate an internal ID (`E<N+1>`) per Step 1 of Create Flow.
   - Derive a provisional title from the first ~10 words of the description (strip URLs and `@` mentions for the slug; keep them in the description body).
   - Do NOT run the Jira Import Flow (there's no Jira ID to import from). Skip Step 6.
   - After creating `epic.md`, seed its **Summary** section with the freeform text so the intake context is preserved.
   - Tell the user the epic was created and ask what to do next: create a story in it (`/story create --epic <id>`), import stories from Jira later (`--id <jira-epic-key>` on a re-run), or update the title. Do **not** auto-create stories and do **not** auto-plan.

Heuristic for ID-vs-freeform classification: if the argument contains a space, a URL, an `@` file mention, a newline, or is longer than 40 characters, treat it as freeform. Otherwise try ID-pattern matching. When in doubt, prefer freeform — the worst case is an extra confirmation turn, not silent execution or an unwanted Jira fetch.

### `/epic` (no arguments) — same as list
1. Follow the **List Flow** below

---

## ID Resolution

Given an ID string:
1. Read `docs/progress.md` — if it does not exist, no epics exist yet, return not found
2. Search the **Epics** table for a row where the **ID** column matches the given ID (case-insensitive)
3. If found, return the **Path** column value
4. If not found, also try matching against directory names under `epics/` (the ID may appear as a prefix like `HRAB-7000-team-collaboration`)
5. If still not found, return not found

---

## Create Flow

### 1. Determine the ID

- If `--id` is provided, use it as the epic ID and set `id_source: external`
- If `--id` is not provided, generate an internal ID:
  1. Read `docs/progress.md` if it exists
  2. Scan the Epics table for all IDs matching `E<n>` pattern
  3. Find the highest `n`, increment by 1
  4. If no epics exist, start with `E1`
  5. Set `id_source: internal`

### 2. Build the slug

- Take the title, lowercase it
- Replace spaces with hyphens
- Strip characters that are not alphanumeric or hyphens
- Collapse consecutive hyphens
- Trim to max 50 characters
- Final directory name: `{id}-{slug}` (e.g., `HRAB-7000-team-collaboration` or `E1-team-collaboration`)
- If no title is available yet (will be fetched from Jira), use a temporary slug from the ID only

### 3. Determine the owner

- Run `git config user.name` — if available, use as owner (prefixed with `@`)
- Fall back to `git config user.email`
- Fall back to `"unset"`

### 4. Create the directory structure

```bash
mkdir -p epics/{id}-{slug}/stories
```

### 5. Create epic.md

Write `epics/{id}-{slug}/epic.md` using the **Epic Template** below, filling in all frontmatter fields and section stubs.

### 6. Jira Import (conditional)

**Run this step only when ALL of these conditions are true:**
- `id_source` is `external` (the `--id` flag was used)
- `--no-import` was NOT specified

If conditions are not met, skip to Step 7.

**This is a single continuous operation.** Follow the **Jira Import Flow** defined below in full — do NOT pause between its sub-steps and do NOT ask the user for confirmation before planning or executing. The Jira Import Flow handles:
- Enrich `epic.md` with Jira data (summary, description, metadata)
- Import child stories as local story directories
- Plan each imported story (unless `--no-plan` was specified) — this runs sub-agents in parallel
- Update the slug/directory name if a title was fetched from Jira and no `--title` was provided

**After the Jira Import Flow returns, continue directly to Step 7 and Step 8 of this Create Flow without stopping.** The only user checkpoint in the entire Create Flow is the approval prompt in Step 8.

### 7. Initialize or update docs/progress.md

- If `docs/progress.md` does not exist, create it using the **Progress Template** below
- Add a row to the **Epics** table:
  `| {id} | {id_source} | {title} | draft | {owner} | 0/0 | epics/{id}-{slug}/ |`
- If stories were imported in Step 6, add a row to the **Stories** table for each:
  `| {story_id} | external | {story_title} | active | {owner} | {epic_id} | intake | epics/{epic_id}-{slug}/stories/{story_id}-{story_slug}/ |`
- Update the **Summary** section counts and `Last updated` timestamp
- If stories were imported, update the Stories count in the epic's row (e.g., `0/5`)

### 8. Present to the user

Branch on the outcome of Steps 6–7:

#### 8a. Stories imported AND planned

Print a consolidated summary:

```
## Epic {id}: {title}
Jira status: {jira_status} • Owner: {owner} • Path: {path}

Planned {N} stories for approval:

| ID | Title | Jira Status | Phase | Key Scope | Top Risks |
|----|-------|-------------|-------|-----------|-----------|
| ... | ... | ... | pending_approval | ... | ... |
```

If any stories were skipped (already existed locally), list them under "Skipped — already imported".
If any stories failed planning, list them under "Failed planning — please run `/story resume <id>`".

Then **request approval with the `AskUserQuestion` tool** (not with a prose prompt):

- Question: `How do you want to proceed with the {N} planned stories?`
- Header: `Epic approval`
- Options:
  1. `Approve all` — "Start coding every planned story."
  2. `Approve a subset` — "Use the free-form answer to list the story IDs to approve (e.g., `HRAB-7026, HRAB-7028`). Others stay in pending_approval."
  3. `Request changes` — "Use the free-form answer in the form `change <ID>: <what to change>`. I'll revise and re-present."
  4. `Cancel` — "Leave every story in pending_approval and stop."

This is the **only** human checkpoint in `/epic create`. Do not call any other tool in the same message as the approval prompt, and do not progress any story past `pending_approval` until the `AskUserQuestion` tool has returned with the user's selection.

###### Auto-Mode Exception (non-negotiable)

This batch approval gate **MUST NOT** be bypassed even when Auto Mode is active or any other "be more autonomous / minimize interruptions" directive is in force. Plan approval is never a "routine decision" — it is a hard human checkpoint. The model does not have authority to self-approve on the user's behalf. See [rules.md](../story/references/rules.md) Rule 11.

##### Handling the response

Parse the response into three sets: `approved`, `changes_requested` (with edit instructions per story), and `on_hold` (untouched). Then:

1. **For each story in `changes_requested`:**
   - Update `story.md` frontmatter: `current_phase: revising`, log in Phase History.
   - Update `decisions.md` with the requested change and reason.
   - Re-invoke a planner sub-agent (same contract as Step 6) with the change as additional instruction. When it returns, set `current_phase: pending_approval` and append the story back into the approval prompt for the next round.
2. **For each story in `on_hold`:** leave `current_phase: pending_approval`. They can be resumed later via `/story resume <id>`.
3. **For `approved`:** run the **Auto-Dispatch Block** below.

##### Auto-Dispatch Block (approved stories only)

Goal: take every approved story from `pending_approval` through `task_generation` → `executing` without further prompting, respecting concurrency safety.

1. **Emit a status line:** `{M} stories approved. Choosing execution mode…`
2. **Flip each approved story to `task_generation`** — update `story.md` frontmatter, Phase History row, and `docs/progress.md` Phase column.
3. **Determine cross-story concurrency.** For the approved set, inspect each story's **Affected Pages / Modules** and **Related Backend Contracts / APIs** sections. Build a conflict graph:
   - Edge = "these two stories touch overlapping files/modules" OR "story A's contract is consumed by story B".
   - Independent clusters can run concurrently; connected stories must run sequentially, in producer-first order.
4. **Select mode per cluster** using the [Claude Teams Capability Check](#claude-teams-capability-check):
   - Cluster size 1 → `sequential` (trivially).
   - Cluster size ≥2 AND stories are disjoint → `parallel-agents`, or `teams` when available and beneficial (e.g., FE+BE pair with a shared contract to align).
   - Cluster with contract coupling → run the **Contract Alignment** step first: write the shared API shape (endpoint, request/response schema, error codes) into every participating story's `decisions.md`, then launch.
5. **Log the decision** in `epic.md` under an "Execution Plan" note and in each story's `decisions.md` (mode + peers + reasoning).
6. **Emit a status line:** `Execution plan: {N_parallel_pairs} parallel, {N_sequential} sequential. Generating tasks.`
7. **Per-story pipeline** — for each story in the execution order:
   - Flip `current_phase: task_generation` (already set above).
   - Invoke a **task-breaker sub-agent** per the [task-breaker role](../story/references/agents/task-breaker.md) and the [phase-tasks instructions](../story/references/phase-tasks.md). Inputs: story.md, acceptance-criteria.md, CLAUDE.md. Post-condition: Tasks section populated, frontmatter `total_tasks` / `current_task` set.
   - Flip `current_phase: executing`, update Phase History and `docs/progress.md`.
   - Invoke **implementer sub-agent(s)** per the [implementer role](../story/references/agents/implementer.md) and the [phase-execution instructions](../story/references/phase-execution.md). Tasks marked `parallelizable: true` in `story.md` run as concurrent `Agent` calls; sequential tasks run one after another.
   - When all tasks are done → flip `current_phase: verifying`. (Verification itself is the user's or a follow-up command's concern — do not auto-run `/story-verify` unless the user has asked for it elsewhere.)
8. **Cross-story orchestration** — launch clusters according to step 4:
   - `parallel-agents` clusters: issue concurrent `Agent` calls in a single message, one per story, with the per-story pipeline as the sub-agent's task.
   - `teams` clusters: use the Teams capability (roles = one per story, shared context = the Contract Alignment block). Same pipeline inside.
   - `sequential` clusters: run one story's pipeline to `verifying` before starting the next.
9. **Report progress** after each story reaches `verifying` or blocks. Final summary after all clusters complete.

**Stop only for:**
- User interruption
- Every approved story has reached `verifying` (done for this command)
- A hard blocker in a story (missing access, repeated 3+ failures, plan conflict that needs the user); blocked stories are reported but do not block other clusters.

#### 8b. Stories imported but NOT planned (`--no-plan`)

- Display the epic header and the imported stories table (Phase = `intake`).
- Note: "Stories have been imported but not yet planned."
- Suggest: `/epic plan {id}` to plan all stories, or `/story resume <id>` to plan individually.

#### 8c. No stories found in Jira

- Display the epic.
- Note: "No child stories found in Jira for {id}."
- Ask: "Would you like to create a story within this epic?"

#### 8d. Import was skipped (`--no-import` or internal ID)

- Display the epic.
- Ask: "Would you like to create a story within this epic?"

---

## Jira Import Flow

This flow runs during epic creation when `id_source` is `external` and `--no-import` is not set. It enriches the epic with Jira data and imports child stories.

### Step 1: Resolve the Atlassian Cloud ID

1. Call `mcp__claude_ai_Atlassian__getAccessibleAtlassianResources` to list available Atlassian sites
2. If the call fails (auth not configured, network error):
   - Log: "Could not connect to Atlassian. Epic created without Jira data. You can add stories manually with `/story create --epic {id}`."
   - Skip the entire Jira Import Flow — continue to Step 7 of Create Flow
3. From the response, identify the appropriate site and extract the `cloudId`
4. If multiple sites are available, try to match by project key prefix from the epic ID

### Step 2: Fetch Epic Details from Jira

1. Call `mcp__claude_ai_Atlassian__getJiraIssue` with:
   - `cloudId`: resolved in Step 1
   - `issueIdOrKey`: the epic ID (e.g., `HRAB-7000`)
   - `responseContentFormat`: `"markdown"`
   - `fields`: `["summary", "description", "status", "priority", "labels", "components", "assignee"]`

2. If the call fails (issue not found, permission denied):
   - Log: "Could not fetch Jira issue {id}. Epic created with provided title only."
   - Skip to Step 3 (still try to find child stories) or skip the entire import if auth-related

3. If successful, enrich `epic.md`:
   - **Title**: if `--title` was not provided, use the Jira `summary` as the title. Update the frontmatter and heading.
   - **Summary section**: populate with Jira `description` (first paragraph or full if short)
   - **Goals section**: if the Jira description contains goal-like content, extract it here
   - **Jira Metadata section**: populate with status, priority, labels, components (see template)
   - **Frontmatter**: set `jira_status` and `jira_url` fields
   - **Owner**: if Jira `assignee` is available, use it (unless already set by git config)
   - If the title changed (fetched from Jira), update the directory name/slug and `epic.md` path

### Step 3: Fetch Child Stories from Jira

1. Call `mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql` with:
   - `cloudId`: resolved in Step 1
   - `jql`: `"Epic Link" = {epic_id} ORDER BY rank ASC`
   - `fields`: `["summary", "description", "status", "issuetype", "priority", "assignee", "labels"]`
   - `maxResults`: `50`
   - `responseContentFormat`: `"markdown"`

2. If the first JQL returns zero results, try the alternate JQL for next-gen Jira projects:
   - `jql`: `parent = {epic_id} ORDER BY rank ASC`

3. If both queries return zero results:
   - Log: "No child stories found in Jira under {epic_id}."
   - Continue to Step 7 of Create Flow (no stories to import)

4. If the query fails (auth error, invalid JQL):
   - Log a warning and skip story import

5. If results span multiple pages (`nextPageToken` present), paginate to collect all results

### Step 4: Deduplicate Against Local State

1. Read `docs/progress.md` if it exists
2. Collect all existing story IDs from the Stories table
3. For each Jira issue returned in Step 3:
   - If its key already exists in progress.md → add to "skipped" list
   - If its key does not exist → add to "to import" list

### Step 5: Create Local Story Directories

For each story in the "to import" list:

1. **Build the story slug**: lowercase Jira summary, replace spaces with hyphens, strip special chars, collapse hyphens, max 50 chars

2. **Create the directory**: `epics/{epic_id}-{epic_slug}/stories/{story_id}-{story_slug}/`

3. **Create `story.md`** from the story template (`~/.dev-workflow/templates/story.md`):
   - `id`: Jira issue key (e.g., `HRAB-7026`)
   - `id_source`: `external`
   - `title`: from Jira `summary`
   - `status`: `active`
   - `epic`: the epic ID (e.g., `HRAB-7000`)
   - `owner`: from Jira `assignee` if available, else fall back to git user
   - `current_phase`: `intake`
   - `current_task`: `null`
   - `total_tasks`, `completed_tasks`, `blocked_tasks`: `0`
   - `depends_on`: `[]`
   - `jira_status`: the Jira status value (informational only)
   - `created`, `last_updated`: current ISO timestamp
   - **Summary section**: populated with Jira `description` (or placeholder if empty)
   - **Context section**: "Imported from Jira issue {story_id}. Original Jira status: {status}."
   - All other sections: leave template placeholders (filled during intake phase)

4. **Create `acceptance-criteria.md`** from template (`~/.dev-workflow/templates/acceptance-criteria.md`):
   - Set `story` field to the story ID

5. **Create `decisions.md`** from template (`~/.dev-workflow/templates/decisions.md`):
   - Set `story` field to the story ID
   - Add initial decision D1: "Story imported from Jira epic {epic_id}" with reason "Automated import during epic creation"

### Step 6: Plan Imported Stories

**Skip this step ONLY if `--no-plan` was specified.** In that case, stories remain in `intake` and the user must later run `/epic plan <id>` or `/story resume <id>`. Otherwise, this step is **mandatory** — do not stop before completing it and do not ask the user for permission to run it.

Imperative algorithm:

1. **Emit a status line to the user:** `Imported N stories. Planning in parallel…`
2. **Gather shared project context once** — read the project's root `CLAUDE.md` (and nearest sub-project CLAUDE.md if the epic targets a specific area) so sub-agents are not repeating the same exploration. Collect the paths; the content is read by each sub-agent.
3. **Choose the execution mode** using the [Claude Teams Capability Check](#claude-teams-capability-check). For planning, prefer `teams` when available, otherwise `parallel-agents` (cap 3). Planning never uses `sequential` unless only one story exists.
4. **Launch planner sub-agents** per the [Planning Sub-Agent Contract](#planning-sub-agent-contract). That contract defines the exact inputs, prompt, and post-conditions — do not restate them here.
5. **Collect results.** Each sub-agent returns a short summary (id, scope bullets, top risks). Gather them for Step 8.
6. **Reconcile global state:**
   - Update `docs/progress.md` Phase column for every successfully planned story → `pending_approval`.
   - For stories whose sub-agents failed, keep Phase as `intake` and record them in a "Failed Planning" list to surface in Step 8.
7. **Emit a status line:** `Planning complete. Presenting for approval.`

**Do not stop here.** Proceed to Step 7, then Step 8 of the Create Flow.

### Step 7: Update epic.md Linked Stories Table

After all stories are created (and optionally planned), update the **Linked Stories** table in `epic.md`:

```markdown
| {story_id} | {story_title} | active | {phase} | {owner} |
```

Where `{phase}` is `pending_approval` if the story was planned, or `intake` if planning was skipped or failed.

Also update the `last_updated` frontmatter field.

---

## Plan Flow

Plan all unplanned stories within an epic. Triggered by `/epic plan <id>`.

### 1. Load Epic State

1. Read `epic.md` from the resolved path
2. Read `docs/progress.md`
3. Scan the Stories table for rows where **Epic** = this epic's ID
4. Filter for stories in `intake` or `planning` phase — these are the **unplanned stories**
5. If no unplanned stories found, report: "All stories in {epic_id} are already planned or beyond planning." and stop.

### 2. Display Planning Summary

Present to the user:
```
## Planning Stories for Epic {id}: {title}

Found {N} unplanned stories:

| ID | Title | Current Phase |
|----|-------|---------------|
| ... | ... | ... |

I'll explore the codebase and generate implementation plans for each story.
```

### 3. Explore the Codebase

Before planning individual stories, gather shared context:
- Read the project's `CLAUDE.md` files for conventions and structure
- Understand the tech stack, build system, testing patterns
- Identify the areas of the codebase most relevant to this epic's goals
- This context will be provided to all story planning sub-agents

### 4. Plan Stories Using Sub-Agents

Delegate to the [Planning Sub-Agent Contract](#planning-sub-agent-contract). That section defines the exact inputs, prompt, parallelism, and post-conditions for each planner sub-agent — do not restate them.

Mode selection: use the [Claude Teams Capability Check](#claude-teams-capability-check) to pick `teams` or `parallel-agents` (cap 3). Log the mode in the epic's "Execution Plan" note and in each story's `decisions.md`.

Emit a status line before launching: `Planning {N} unplanned stories in parallel…`
Emit a status line after completion: `Planning complete. Presenting for approval.`

### 5. Update Global State

After all sub-agents complete:
- Update `docs/progress.md` Phase column for each planned story
- Update `epic.md` Linked Stories table with current phases
- Update `last_updated` timestamps

### 6. Present Results for Approval

Print a short summary of all planned stories to chat:

```
## Planning Complete for Epic {id}: {title}

Planned {N} stories:

| ID | Title | Key Scope Items | Risks |
|----|-------|----------------|-------|
| ... | ... | ... | ... |

{If any stories failed planning, list them here with the reason}

Full plans are in each story's story.md file.
```

Then **request approval with the `AskUserQuestion` tool** using the same question, header, and options defined in [Create Flow → Step 8a](#8a-stories-imported-and-planned) (Approve all / Approve a subset / Request changes / Cancel). Do not emit a prose "respond with one of…" prompt — the `AskUserQuestion` tool forces a real user turn and prevents self-approval.

The same **Auto-Mode Exception** from Step 8a applies here: this gate must not be bypassed under Auto Mode or any "minimize interruptions" directive. See [rules.md](../story/references/rules.md) Rule 11.

Handle the response exactly as in **Create Flow → Step 8a → Handling the response** and run the same **Auto-Dispatch Block** for approved stories. Do not duplicate that logic here; refer to [Step 8a](#8a-stories-imported-and-planned).

---

## Resume Flow

1. Read `epic.md` from the resolved path
2. Read `docs/progress.md`
3. Scan the **Stories** table for rows where the **Epic** column matches this epic's ID
4. Display:
   - Epic title, status, owner, created date
   - Summary and Goals sections from epic.md
   - Table of linked stories with: ID, title, status, phase, owner
   - Completion stats (e.g., "3/7 stories complete")
5. If all linked stories have status `complete`, suggest marking the epic as complete
6. Offer actions:
   - If there are stories in `intake` or `planning` phase: "Plan unplanned stories with `/epic plan {id}`"
   - Create a new story in this epic
   - Resume an existing story (list incomplete ones)
   - Update epic status

---

## Status Flow

Same as Resume Flow but read-only — display the information without offering interactive actions.

---

## List Flow

1. Read `docs/progress.md` — if it does not exist, report "No epics found. Use `/epic create` to create one."
2. Parse the **Epics** table
3. Display all epics in a table: ID, Title, Status, Owner, Stories (completion count)
4. If the table is empty, report "No epics found."

---

## Epic Template

```markdown
---
id: "{{id}}"
id_source: {{id_source}}
title: "{{title}}"
status: draft
owner: "{{owner}}"
created: "{{timestamp}}"
last_updated: "{{timestamp}}"
---

# {{title}}

## Summary

<!-- One paragraph overview of what this epic is about -->

## Goals

<!-- What this epic aims to achieve -->

## Scope

<!-- What is included in this epic -->

## Non-Goals

<!-- What is explicitly out of scope -->

## Dependencies

<!-- External dependencies or prerequisites -->

## Linked Stories

<!-- Auto-maintained — do not edit manually. Populated from docs/progress.md -->

| ID | Title | Status | Phase | Owner |
|----|-------|--------|-------|-------|
```

**When Jira data is available**, the epic.md is enriched with additional frontmatter and a Jira Metadata section:

```yaml
# Additional frontmatter fields (only for Jira-imported epics)
jira_status: "{{jira_status}}"
jira_url: "{{jira_url}}"
```

```markdown
## Jira Metadata

| Field | Value |
|-------|-------|
| **Jira Status** | {{jira_status}} |
| **Priority** | {{priority}} |
| **Labels** | {{labels}} |
| **Components** | {{components}} |
| **Imported** | {{timestamp}} |
```

This section is inserted between **Dependencies** and **Linked Stories** only when Jira data is fetched. For internally-created epics or when Jira fetch fails, this section is omitted entirely.

---

## Progress Template

When `docs/progress.md` does not exist, create it with this structure:

```markdown
# Project Progress

## Epics

| ID | Source | Title | Status | Owner | Stories | Path |
|----|--------|-------|--------|-------|---------|------|

## Stories

| ID | Source | Title | Status | Owner | Epic | Phase | Path |
|----|--------|-------|--------|-------|------|-------|------|

## Summary

- **Total epics:** 0
- **Total stories:** 0
- **Last updated:** ---
```

---

## Planning Sub-Agent Contract

This block is the single source of truth for how the orchestrator plans a batch of imported or unplanned stories. It is referenced by **Create Flow → Jira Import Flow → Step 6** and by **Plan Flow → Step 4**. Do not duplicate this logic.

### Inputs passed to each planner sub-agent

- Absolute path to the story's `story.md` (so the agent can read and edit it)
- Absolute path to the story's `acceptance-criteria.md`
- Absolute path to the story's `decisions.md`
- Absolute path to the parent `epic.md`
- Path to the project's `CLAUDE.md` files (root + nearest to the story's likely target area)
- The [planner agent role](../story/references/agents/planner.md) (pass as role instruction)
- The [phase-planning instructions](../story/references/phase-planning.md) (pass as process instruction)
- Explicit task prompt: *"Plan this story. Read the story.md (its Summary/Context already include the Jira description), the epic.md for overall goals, and explore the codebase (start from CLAUDE.md). Fill every plan section in story.md: Summary, Scope, Out of Scope, Affected Pages/Modules, Related Backend Contracts/APIs, Assumptions, Dependencies, Risks, Implementation Strategy. Write testable criteria into acceptance-criteria.md following the categories in phase-planning.md. Do NOT ask clarifying questions — make reasonable assumptions from the Jira description and the codebase, and record them in the Assumptions section and in decisions.md. When done, set story.md frontmatter current_phase to pending_approval, update last_updated, append a row to the Phase History table, and update the Phase column for this story in docs/progress.md. Return a short summary: story id, key scope bullets, top risks."*

### Parallelism

- Launch up to 3 planner sub-agents concurrently via the `Agent` tool (single message, multiple tool uses).
- When a batch completes, launch the next batch until every story is processed.
- The orchestrator MAY upgrade this to Claude Teams — see the [Claude Teams Capability Check](#claude-teams-capability-check) section.

### Post-conditions (per story)

- `story.md` frontmatter: `current_phase: pending_approval`, `last_updated` set, Phase History has a new row.
- All plan sections in `story.md` are filled with concrete content (no template placeholders left).
- `acceptance-criteria.md` has testable criteria covering every scope item.
- `decisions.md` has entries for any non-trivial assumption.
- `docs/progress.md` Phase column reflects `pending_approval` for the story.

### Error handling

- A sub-agent failure leaves its story in `intake` or `planning`. Log the failure, continue with the remaining stories, and surface the failed stories in the final summary so the user can re-run via `/story resume <id>` or `/epic plan <id>`.

---

## Claude Teams Capability Check

The orchestrator may use Claude Teams whenever coordinated parallel sub-agents provide a clear benefit (parallel planning of many stories, parallel execution of disjoint stories, parallel verification). Teams is an optional capability — the workflow must work without it.

### Capability check (run before choosing Teams)

Before opting into Teams, the orchestrator checks availability. Use whichever of the following signals are present in the current Claude instance — if none are present, assume Teams is NOT available:

1. A `ClaudeTeams*` / `Team*` tool is exposed in the current tool set.
2. An environment variable or setting indicating Teams is enabled (e.g., `CLAUDE_TEAMS=1`, or an explicit entry in `.claude/settings.json`).
3. A project-level CLAUDE.md directive like "Use Claude Teams for parallel story execution".

Record the result of the check (available / unavailable) once per flow — do not re-check between stories in the same run.

### Mode selection

After the capability check, the orchestrator picks one of three modes for a given parallelizable batch:

| Mode | When to use | How |
|------|-------------|-----|
| `teams` | Teams available AND the batch benefits from coordinated roles (e.g., a frontend/backend pair that must align on a contract, or 3+ stories needing shared scratch space). | Use the Teams tool/API with one agent per story (or per role) and the shared contract/spec as the shared context. |
| `parallel-agents` | Teams unavailable OR the batch is simple disjoint work with no coordination needed. | Launch up to 3 concurrent sub-agents via the `Agent` tool in a single message. |
| `sequential` | Stories share files/modules, or one story's output is the input for another, or parallelism is not safe. | Run one sub-agent at a time. |

### Logging the decision

Whenever the orchestrator launches a batch, log:

- **In `epic.md`** under a new "Execution Plan" note: the batch, the chosen mode, and one sentence of reasoning.
- **In each participating story's `decisions.md`**: the same mode and the peers it ran alongside (if any).

This makes the concurrency decision auditable after the fact.

### Fallback rules

- Teams unavailable → downgrade to `parallel-agents`.
- File-overlap risk detected in `parallel-agents` → downgrade to `sequential`.
- Never block progress waiting for Teams to become available.

---

## Updating the Linked Stories Table

When displaying an epic (resume or status), rebuild the **Linked Stories** table in `epic.md`:

1. Scan the Stories table in `docs/progress.md` for rows where Epic = this epic's ID
2. Overwrite the table rows in the **Linked Stories** section of `epic.md`
3. Update the `last_updated` frontmatter field

This keeps `epic.md` current without requiring manual maintenance.

---

## Epic Status Transitions

Status is managed manually, but the workflow should **suggest** transitions:

| Current | Condition | Suggested Transition |
|---------|-----------|---------------------|
| `draft` | First story created or work begins | Suggest `active` |
| `draft` | Stories imported from Jira | Suggest `active` |
| `active` | All linked stories complete | Suggest `complete` |
| `active` | Blocked by external dependency | Suggest `blocked` |
| `blocked` | Blocker resolved | Suggest `active` |
| `complete` | No longer relevant or superseded | Suggest `archived` |

When suggesting a transition, explain why and ask the user to confirm before making the change.

---

## Error Handling

- **docs/progress.md missing:** Create it on epic creation; report "no epics" on list/status/resume
- **Epic directory not found for resolved ID:** Report the inconsistency, suggest checking `docs/progress.md` for stale entries
- **Malformed progress.md:** Report the issue, attempt to reconstruct from `epics/` directory scan
- **Duplicate ID:** Refuse to create, report the existing epic with that ID

### Jira Import Errors

- **Atlassian MCP tools not available or auth not configured:** Log "Atlassian integration is not available. Epic created without Jira data." Create the epic without import. Suggest adding stories manually.
- **Cloud ID resolution fails:** Log warning, create epic without Jira data.
- **Epic issue not found in Jira:** Log "Issue {id} not found in Jira. The external ID will be used as-is." Create epic with the user-provided title.
- **JQL query fails:** Log warning with which JQL was attempted, create epic without importing stories.
- **Individual story creation fails:** Log the failure for that specific story, continue with remaining stories. Present partial results at the end.
- **Rate limiting from Atlassian:** Retry once after a brief pause. If it fails again, log and skip remaining import.
- **Large epic (50+ stories):** Paginate using `nextPageToken`. Cap at 100 stories and warn the user if more exist.
