---
name: feature-init
description: "[DEPRECATED] Use /story-init instead. Redirects to the /story-init command."
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

# Deprecated — Use /story-init

> **This command is deprecated.** The `/feature-init` command has been replaced by `/story-init`.

## Migration

| Old command | New command |
|-------------|------------|
| `/feature-init <name>` | `/story-init --title "<name>"` or `/story-init <id>` |

## Redirect behavior

1. Print deprecation notice to the user
2. Map arguments: treat `<name>` as a story title for creation, or look up existing story by name/ID in `docs/progress.md`
3. Proceed with the full `/story-init` skill behavior as defined in `skills/story-init/SKILL.md`
