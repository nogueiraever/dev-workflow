---
name: feature
description: "[DEPRECATED] Use /story instead. Redirects to the /story command."
argument-hint: "[<name> | resume <name>]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
---

# Deprecated — Use /story

> **This command is deprecated.** The `/feature` command has been replaced by `/story`.

## Migration

| Old command | New command |
|-------------|------------|
| `/feature <name>` | `/story create --title "<name>"` or `/story <id>` |
| `/feature resume <name>` | `/story resume <id>` |
| `/feature` (list) | `/story list` |

## Redirect behavior

1. Print deprecation notice to the user
2. Map the arguments to the `/story` equivalent:
   - If no arguments → run `/story list`
   - If `resume <name>` → look up `docs/progress.md` for a story matching `<name>` in the title or path, then run the resume flow from `/story`
   - If `<name>` → look up `docs/progress.md` for a story matching `<name>`, resume if found, or offer to create a new story with that title

3. If old-style `docs/features/<name>/` directory exists but no `docs/progress.md` entry:
   - Inform the user that the old feature format was detected
   - Suggest running `/workflow-setup` to initialize the new structure
   - Offer to migrate the old feature directory to the new story format

4. Proceed with the `/story` skill logic using the references from `skills/story/references/`

## Important

After printing the deprecation notice, follow the FULL `/story` skill behavior as defined in `skills/story/SKILL.md`. Load and follow all references from `skills/story/references/` — this wrapper exists only to provide backward compatibility for the command name.
