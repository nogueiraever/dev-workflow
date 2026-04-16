---
name: feature-tasks
description: "[DEPRECATED] Use /story-tasks instead. Redirects to the /story-tasks command."
argument-hint: "<name>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# Deprecated — Use /story-tasks

> **This command is deprecated.** The `/feature-tasks` command has been replaced by `/story-tasks`.

## Migration

| Old command | New command |
|-------------|------------|
| `/feature-tasks <name>` | `/story-tasks <id>` |

## Redirect behavior

1. Print deprecation notice to the user
2. Map arguments: look up story by name or ID in `docs/progress.md`
3. Proceed with the full `/story-tasks` skill behavior as defined in `skills/story-tasks/SKILL.md`
