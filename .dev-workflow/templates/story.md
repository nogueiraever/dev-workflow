---
id: "{{id}}"
id_source: "{{id_source}}"
title: "{{title}}"
status: draft
epic: {{epic}}
owner: "{{owner}}"
current_phase: intake
current_task: null
total_tasks: 0
completed_tasks: 0
blocked_tasks: 0
depends_on: []
created: "{{timestamp}}"
last_updated: "{{timestamp}}"
jira_status: "{{jira_status}}"
---

# {{id}}: {{title}}

## Summary
<!-- One paragraph overview of what this story delivers -->

## Context
<!-- Why this work is needed, background information -->

## Scope
<!-- Bulleted list of what's included -->

## Out of Scope
<!-- Explicitly excluded items -->

## Affected Pages / Modules

| Area | Type | Impact |
|------|------|--------|
| _page or module name_ | _frontend / backend / infra_ | _description of change_ |

## Related Backend Contracts / APIs

| Endpoint / Contract | Method | Change Type |
|---------------------|--------|-------------|
| _/api/example_ | _GET/POST/PUT/DELETE_ | _new / modified / consumed_ |

## Assumptions
<!-- Things treated as true that could invalidate the plan -->

## Dependencies

| Dependency | Type | Status |
|-----------|------|--------|
| _description_ | _technical / external / data_ | _available / pending / unknown_ |

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|

## Implementation Plan
<!-- Approach, phase breakdown, technical notes -->

### Approach

_High-level description of how this will be built._

### Phase Breakdown

1. _Phase description_
2. _Phase description_

### Technical Notes

_Any specific technical details, patterns to follow, or constraints._

## Tasks

### Execution Order
<!-- Parallel/sequential diagram will be generated here -->

```
[T1] ──→ [T3] ──→ [T5]
[T2] ──→ [T4] ──┘
```

<!-- Tasks will be added here during task generation phase -->
<!--
Example task format:

### T1: Task title
- **Status:** todo
- **Dependencies:** none
- **Parallelizable:** true
- **Description:** What needs to be done, where, and how to verify
- **Linked Criteria:** AC1, V1
- **Notes:** Any additional context

Status values: todo | in_progress | blocked | done
-->

## Phase History

| Phase | Entered | Exited | Notes |
|-------|---------|--------|-------|
| intake | {{timestamp}} | — | Story created |
