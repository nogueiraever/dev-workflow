---
name: feature-verify
description: "[DEPRECATED] Use /story-verify instead. Redirects to the /story-verify command."
argument-hint: "<name>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# Deprecated — Use /story-verify

> **This command is deprecated.** The `/feature-verify` command has been replaced by `/story-verify`.

## Migration

| Old command | New command |
|-------------|------------|
| `/feature-verify <name>` | `/story-verify <id>` |

## Redirect behavior

1. Print deprecation notice to the user
2. Map arguments: look up story by name or ID in `docs/progress.md`
3. Proceed with the full `/story-verify` skill behavior as defined in `skills/story-verify/SKILL.md`
