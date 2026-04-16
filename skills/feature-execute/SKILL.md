---
name: feature-execute
description: "[DEPRECATED] Use /story-execute instead. Redirects to the /story-execute command."
argument-hint: "<name>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
---

# Deprecated — Use /story-execute

> **This command is deprecated.** The `/feature-execute` command has been replaced by `/story-execute`.

## Migration

| Old command | New command |
|-------------|------------|
| `/feature-execute <name>` | `/story-execute <id>` |

## Redirect behavior

1. Print deprecation notice to the user
2. Map arguments: look up story by name or ID in `docs/progress.md`
3. Proceed with the full `/story-execute` skill behavior as defined in `skills/story-execute/SKILL.md`
