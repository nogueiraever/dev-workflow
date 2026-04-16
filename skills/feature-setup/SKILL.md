---
name: feature-setup
description: "[DEPRECATED] Use /workflow-setup instead. Redirects to the /workflow-setup command."
argument-hint: "[--force]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
---

# Deprecated — Use /workflow-setup

> **This command is deprecated.** The `/feature-setup` command has been replaced by `/workflow-setup`.

## Migration

| Old command | New command |
|-------------|------------|
| `/feature-setup` | `/workflow-setup` |
| `/feature-setup --force` | `/workflow-setup --force` |

## Redirect behavior

1. Print deprecation notice to the user
2. Pass all arguments through to `/workflow-setup`
3. Proceed with the full `/workflow-setup` skill behavior as defined in `skills/workflow-setup/SKILL.md`
