---
name: workflow-setup
description: "Initialize the story workflow in the current project. Copies .dev-workflow/ (agents, orchestrators, prompts, rules, templates) into the project and creates the initial directory structure (docs/, docs/progress.md, docs/epics/, docs/stories/). Run this once per project before using /story. Safe to re-run -- only copies missing files unless --force is used."
argument-hint: "[--force]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
---

# Workflow Setup

Initialize the autonomous story workflow in the current project.

## What This Does

Sets up two things:

1. **`.dev-workflow/`** -- workflow infrastructure (agents, orchestrators, prompts, rules, templates) that guide the `/story` workflow
2. **Directory structure** -- `docs/`, `docs/epics/`, `docs/stories/` directories and the global `docs/progress.md` index

These must exist in the project for `/story` and its sub-commands to work.

## Process

### Step 1: Locate Plugin Root

The plugin root is the directory containing the `.dev-workflow/` source files. Find it by navigating up from this skill's location:

```
Plugin root = ../../  (relative to skills/workflow-setup/SKILL.md)
```

Use bash to resolve the absolute path. Verify the directory contains both `skills/` and `.dev-workflow/`.

### Step 2: Check Current State

Determine what already exists in the target project (current working directory):

- `.dev-workflow/` directory and its contents
- `docs/` directory
- `docs/progress.md` file
- `docs/epics/` directory
- `docs/stories/` directory

Parse `$ARGUMENTS` for flags:
- **`--force`**: Overwrite existing files with the latest versions from the plugin bundle
- **No flag (default)**: Only copy missing files. Skip files that already exist. Safe to re-run.

### Step 3: Copy .dev-workflow/

Copy from the plugin's `.dev-workflow/` directory to the project root. The target structure:

```
.dev-workflow/
  agents/
    planner.md
    task-breaker.md
    implementer.md
    reviewer.md
    verifier.md
    tracker.md
  orchestrators/
    (all orchestrator files)
  prompts/
    (all prompt files)
  rules/
    core-rules.md
  templates/
    (story templates -- story.md, acceptance-criteria.md, decisions.md)
```

**Copy logic:**
- Walk the plugin's `.dev-workflow/` directory recursively
- For each file:
  - If `--force`: copy (overwrite if exists)
  - If no `--force`: skip if file already exists at the target path, copy if missing
- Create subdirectories as needed

### Step 4: Create Directory Structure

Create the following directories if they don't exist:

```
docs/                   # Root docs directory
docs/progress.md        # Global story index (create from template if missing)
docs/epics/             # Epic directories will live here
docs/stories/           # Standalone story directories will live here
```

**For `docs/progress.md`:** If it doesn't exist, create it with the standard header:

```markdown
# Progress

| ID | Title | Status | Phase | Path | Created | Last Updated |
|----|-------|--------|-------|------|---------|--------------|
```

If it already exists, do NOT overwrite it (even with `--force` -- this file contains live state).

### Step 5: Handle Legacy Structure

Check if the old feature workflow structure exists:

- `docs/features/` directory
- `docs/features/_template/` directory

If found, inform the user:

```
Note: Found legacy feature workflow structure at docs/features/.
The new story workflow uses docs/stories/ and docs/epics/ instead.
A migration may be available via the main /story command.
The old structure has been left in place -- you can remove it manually
when you're ready.
```

Do NOT delete or modify the old structure.

### Step 6: Report

Tell the user what was set up:

```
Story workflow initialized in [project-root]:

Copied:
  .dev-workflow/agents/       -- 6 agent role definitions
  .dev-workflow/orchestrators/ -- workflow orchestrators
  .dev-workflow/prompts/      -- phase prompts
  .dev-workflow/rules/        -- core workflow rules
  .dev-workflow/templates/    -- story file templates

Created:
  docs/                       -- documentation root
  docs/progress.md            -- global story index
  docs/epics/                 -- epic directories
  docs/stories/               -- standalone story directories

You can now use:
  /story create --id <id> --title "..."  -- start a new story
  /story resume <id>                     -- resume an existing story
  /story list                            -- list all stories
```

If some files were skipped (already existed), list them separately:

```
Skipped (already exist):
  .dev-workflow/agents/planner.md
  .dev-workflow/rules/core-rules.md
  ...

Use --force to overwrite existing files with the latest versions.
```

If `--force` was used, note that:

```
Force mode: overwrote existing .dev-workflow/ files with latest versions.
Note: docs/progress.md was preserved (contains live state).
```

## Notes

- **Safe to re-run.** Without `--force`, it only adds missing files. This makes it safe to run after plugin updates to pick up new files.
- **With `--force`**, it overwrites all `.dev-workflow/` files (useful after plugin updates) but never overwrites `docs/progress.md` since that contains live story tracking state.
- The `.dev-workflow/` files are reference material -- you can customize them per project after copying. Running with `--force` later will overwrite your customizations.
- Unlike the old `feature-setup`, this does NOT copy `docs/features/_template/`. Story templates live in `.dev-workflow/templates/` instead.
- The `docs/epics/` and `docs/stories/` directories are created under `docs/`.
