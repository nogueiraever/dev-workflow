# Phase 6: Closeout

**Status value:** `closeout` → `complete`
**Agent:** [tracker](agents/tracker.md)

## Objective

Produce a final summary of the story implementation. Document what was completed, any remaining items, and close out the story tracking.

## Process

### 1. Compile Final Summary

Read all story files and produce a comprehensive summary in the Current Status section of `story.md`.

Update the **Current Status** section:

```markdown
## Current Status

**Phase:** Complete
**Overall:** Story implementation finished

### Summary

[2-3 paragraph summary of what was built, how it works, and any notable decisions]

### Key Statistics

- **Total tasks:** N
- **Completed:** N
- **Blocked:** N (with reasons)
- **Decisions made:** N
- **Acceptance criteria:** N passed / N total
```

### 2. Document Completed Items

List every completed task in the Current Status section:

```markdown
### Completed Items

- T1: [title] — done
- T2: [title] — done
- ...
```

### 3. Document Remaining Items

If any work remains (blocked tasks, deferred items, follow-ups):

```markdown
### Remaining Items

#### Blocked
- T{N}: [title] — blocked because [reason]

#### Optional Follow-ups
- [description of enhancement or improvement identified during implementation]
```

### 4. List Key Decisions

Summarize the most important decisions from `decisions.md`:

```markdown
### Key Decisions

- D1: [decision] — [one-line reason]
- D2: [decision] — [one-line reason]
```

### 5. Finalize Tracking

Update `story.md` frontmatter:
- `status: complete`
- `current_phase: complete`
- `current_task: null`
- `last_updated: <now>`

Log the final phase transition in the Phase History section.

Update `docs/progress.md`:
- Status column: `complete`
- Phase column: `complete`
- Last Updated column: `<now>`

### 6. Present to User

Display the final summary to the user:

```
## Story Complete: [id] — [title]

[Brief summary of what was built]

**Stats:** [X] tasks completed, [Y] decisions made, [Z/W] acceptance criteria passed

**Files:** {story-path}/

### What was built:
- [key deliverable 1]
- [key deliverable 2]

### Remaining (if any):
- [blocked items or follow-ups]

All tracking documents have been updated.
```

## Exit Criteria

- `story.md` Current Status section has a complete final summary
- `story.md` frontmatter shows `status: complete`, `current_phase: complete`
- Phase History section is complete with all transitions
- `docs/progress.md` shows status: complete for this story
- User has been presented with the final summary
