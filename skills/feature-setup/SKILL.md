---
name: feature-setup
description: "Initialize the feature workflow in the current project. Copies .ai-workflow/ (orchestrator, agents, prompts, rules) and docs/features/_template/ (tracking templates) into the project. Run this once per project before using /feature. Safe to re-run — only copies missing files."
argument-hint: "[--force]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
---

# Feature Workflow Setup

Initialize the autonomous feature workflow in the current project.

## What This Does

Copies two directory trees from the plugin bundle into the current project:

1. **`.ai-workflow/`** — orchestrator, agents, prompts, and rules that guide the workflow
2. **`docs/features/_template/`** — markdown templates used to create feature tracking files

These files must exist in the project for `/feature` to work.

## Process

### Step 1: Locate Plugin Root

The plugin root is the directory containing `.claude-plugin/plugin.json`. Find it by navigating up from this skill's location:

```
Plugin root = ../../  (relative to skills/feature-setup/SKILL.md)
```

Use bash to resolve the absolute path. Look for the directory that contains both `.claude-plugin/` and `.ai-workflow/`.

### Step 2: Check Current State

Check if the target project already has:
- `.ai-workflow/` directory
- `docs/features/_template/` directory

If `$ARGUMENTS` contains `--force`, overwrite existing files.
Otherwise, skip files that already exist and only copy missing ones.

### Step 3: Copy .ai-workflow/

Copy from the plugin's bundled `.ai-workflow/` directory to the project root:

```
.ai-workflow/
├── orchestrators/feature-orchestrator.md
├── agents/
│   ├── planner.md
│   ├── task-breaker.md
│   ├── implementer.md
│   ├── reviewer.md
│   ├── verifier.md
│   └── tracker.md
├── prompts/
│   ├── feature-intake.md
│   ├── plan-generation.md
│   ├── task-generation.md
│   ├── execution-engine.md
│   ├── verification.md
│   └── resume-feature.md
└── rules/
    └── core-rules.md
```

### Step 4: Copy docs/features/_template/

Copy from the plugin's bundled `docs/features/_template/` to the project:

```
docs/features/_template/
├── plan.md
├── tasks.md
├── acceptance-criteria.md
├── progress.md
└── decisions.md
```

Also ensure `docs/features/` directory exists (where actual feature data will live).

### Step 5: Report

Tell the user what was copied:

```
Feature workflow initialized in [project-root]:

Copied:
  .ai-workflow/           — orchestrator, agents, prompts, rules
  docs/features/_template/ — feature tracking templates

You can now use:
  /feature new <name>     — start a new feature
  /feature resume <name>  — resume an existing feature
  /feature                — list active features
```

If some files were skipped (already existed), list them.

## Notes

- This is safe to re-run. Without `--force`, it only adds missing files.
- With `--force`, it overwrites everything (useful after plugin updates).
- The `.ai-workflow/` files are reference material — you can customize them per project after copying.
