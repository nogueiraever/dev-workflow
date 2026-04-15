---
name: feature-init
description: "Manual entrypoint: run only the intake and planning phases for a feature. Creates the feature directory, gathers requirements, generates plan and acceptance criteria, and presents for approval. Does NOT proceed to task generation or execution. Use when you want to plan a feature without starting implementation."
argument-hint: "<feature-name>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# Feature Init (Manual Entrypoint)

This runs only Phases 1-2 of the feature workflow: Intake and Planning.

## Process

### 1. Validate Arguments

`$ARGUMENTS` must contain a feature name. If empty, ask for one.

Slugify the name: lowercase, hyphens, no special chars.

### 2. Create or Load Feature

**If `docs/features/<name>/` does not exist:**
- Copy all files from `docs/features/_template/`
- Replace `{{feature-name}}` with the feature name
- Replace `{{timestamp}}` with current ISO timestamp

**If it already exists:**
- Read `progress.md` to check current state
- If already past planning (task_generation, executing, etc.), warn the user and suggest `/feature resume <name>` instead
- If in intake or planning, continue from current state

### 3. Run Phase 1: Intake

Follow the process in the feature skill's [phase-intake.md](../feature/references/phase-intake.md):
- Parse the user's feature request
- Explore the codebase for context
- Ask clarifying questions if needed
- Write initial notes to plan.md

### 4. Run Phase 2: Planning

Follow the process in the feature skill's [phase-planning.md](../feature/references/phase-planning.md):
- Generate complete plan.md
- Generate acceptance-criteria.md
- Set status to `pending_approval`
- Present plan to user for review

### 5. Stop

After presenting the plan (approved or not), **stop here**. Do not proceed to task generation.

If the user approves and wants to continue, suggest: `/feature resume <name>` to pick up from task generation.

## Rules

Follow [rules.md](../feature/references/rules.md) for all tracking and markdown updates.
