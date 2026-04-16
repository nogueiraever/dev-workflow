---
name: epic
description: "Manage epics — large initiatives that group related stories. Create, list, resume, and track epics with linked story status. When creating with a Jira ID, automatically imports child stories from Jira. Use: /epic create, /epic list, /epic <id>, /epic status <id>, /epic resume <id>."
argument-hint: "[create [--id ID] [--title TITLE] [--no-import] | list | status <id> | resume <id> | <id>]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - mcp__claude_ai_Atlassian__getAccessibleAtlassianResources
  - mcp__claude_ai_Atlassian__getJiraIssue
  - mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql
---

# Epic Management

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

### `/epic create [--id ID] [--title "TITLE"] [--no-import]` — create a new epic
1. Parse flags:
   - `--id` for external ID (e.g., Jira epic key like `HRAB-7000`)
   - `--title` for epic title
   - `--no-import` to skip fetching stories from Jira
2. If `--title` is missing and `--id` is external, the title may be fetched from Jira during import
3. If `--title` is still missing after import, ask the user for a title
4. Follow the **Create Flow** below

### `/epic list` — list all epics
1. Follow the **List Flow** below

### `/epic status <id>` — detailed epic status
1. Resolve `<id>` to an epic path via **ID Resolution**
2. Follow the **Status Flow** below

### `/epic resume <id>` — resume an epic (show status, offer actions)
1. Resolve `<id>` to an epic path via **ID Resolution**
2. Follow the **Resume Flow** below

### `/epic <id>` — smart routing
1. Attempt **ID Resolution** for `<id>`
2. **Found** → follow the **Resume Flow**
3. **Not found** → tell the user no epic with that ID exists, offer to create one

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

Follow the **Jira Import Flow** defined below. This will:
- Enrich `epic.md` with Jira data (summary, description, metadata)
- Import child stories as local story directories
- Update the slug/directory name if a title was fetched from Jira and no `--title` was provided

### 7. Initialize or update docs/progress.md

- If `docs/progress.md` does not exist, create it using the **Progress Template** below
- Add a row to the **Epics** table:
  `| {id} | {id_source} | {title} | draft | {owner} | 0/0 | epics/{id}-{slug}/ |`
- If stories were imported in Step 6, add a row to the **Stories** table for each:
  `| {story_id} | external | {story_title} | active | {owner} | {epic_id} | intake | epics/{epic_id}-{slug}/stories/{story_id}-{story_slug}/ |`
- Update the **Summary** section counts and `Last updated` timestamp
- If stories were imported, update the Stories count in the epic's row (e.g., `0/5`)

### 8. Present to the user

**If stories were imported from Jira:**
- Display the epic: ID, title, Jira status, owner, path
- Display a table of imported stories: ID, Title, Jira Status, Local Phase
- If any stories were skipped (already existed locally), list them separately
- Ask: "Would you like to resume one of the imported stories?"

**If no stories were found in Jira:**
- Display the epic
- Note: "No child stories found in Jira for {id}"
- Ask: "Would you like to create a story within this epic?"

**If import was skipped (--no-import or internal ID):**
- Display the epic
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

### Step 6: Update epic.md Linked Stories Table

After all stories are created, update the **Linked Stories** table in `epic.md`:

```markdown
| {story_id} | {story_title} | active | intake | {owner} |
```

Also update the `last_updated` frontmatter field.

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
