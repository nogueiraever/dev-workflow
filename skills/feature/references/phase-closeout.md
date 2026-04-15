# Phase 6: Closeout

**Status value:** `closeout` → `complete`
**Agent:** [tracker](agents/tracker.md)

## Objective

Produce a final summary of the feature implementation. Document what was completed, any remaining items, and close out the feature tracking.

## Process

### 1. Compile Final Summary

Read all feature files and produce a comprehensive summary in `progress.md`.

Update the **Current Status** section:

```markdown
## Current Status

**Phase:** Complete
**Overall:** Feature implementation finished

### Summary

[2-3 paragraph summary of what was built, how it works, and any notable decisions]

### Key Statistics

- **Total tasks:** N
- **Completed:** N
- **Blocked:** N (with reasons)
- **Decisions made:** N
- **Acceptance criteria:** N passed / N total
```

### 2. Update Completed Items

List every completed task with its title:

```markdown
## Completed Items

- T1: [title] — done
- T2: [title] — done
- ...
```

### 3. Document Remaining Items

If any work remains (blocked tasks, deferred items, follow-ups):

```markdown
## Remaining Items

### Blocked
- T{N}: [title] — blocked because [reason]

### Optional Follow-ups
- [description of enhancement or improvement identified during implementation]
```

### 4. List Key Decisions

Summarize the most important decisions from `decisions.md`:

```markdown
## Key Decisions

- D1: [decision] — [one-line reason]
- D2: [decision] — [one-line reason]
```

### 5. Finalize Tracking

Update `progress.md` frontmatter:
- `current_phase: complete`
- `current_task: null`
- `last_updated: [now]`

Update `plan.md` frontmatter:
- `status: complete`
- `last_updated: [now]`

Log the final phase transition in the Phase History table.

### 6. Present to User

Display the final summary to the user:

```
## Feature Complete: [feature-name]

[Brief summary of what was built]

**Stats:** [X] tasks completed, [Y] decisions made, [Z/W] acceptance criteria passed

**Files:** docs/features/<name>/

### What was built:
- [key deliverable 1]
- [key deliverable 2]

### Remaining (if any):
- [blocked items or follow-ups]

All tracking documents have been updated.
```

## Exit Criteria

- `progress.md` has a complete final summary
- `progress.md` frontmatter shows `current_phase: complete`
- `plan.md` frontmatter shows `status: complete`
- Phase History table is complete with all transitions
- User has been presented with the final summary
