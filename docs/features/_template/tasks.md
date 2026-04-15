---
feature: "{{feature-name}}"
total_tasks: 0
completed: 0
blocked: 0
last_updated: "{{timestamp}}"
---

# Tasks: {{feature-name}}

## Execution Order

_Dependency diagram showing which tasks can run in parallel vs sequentially._

```
[T1] ──→ [T3] ──→ [T5]
[T2] ──→ [T4] ──┘
```

## Task Breakdown

### T1: _Task title_

| Field | Value |
|-------|-------|
| **ID** | T1 |
| **Title** | _title_ |
| **Description** | _what needs to be done_ |
| **Status** | todo |
| **Dependency IDs** | none |
| **Parallelizable** | true / false |
| **Linked Plan Items** | _which plan section this implements_ |
| **Notes** | _any additional context_ |

<!--
Copy this block for each task. Status values: todo | in_progress | blocked | done

### T{N}: _Task title_

| Field | Value |
|-------|-------|
| **ID** | T{N} |
| **Title** | _title_ |
| **Description** | _what needs to be done_ |
| **Status** | todo |
| **Dependency IDs** | T{X}, T{Y} |
| **Parallelizable** | true / false |
| **Linked Plan Items** | _which plan section this implements_ |
| **Notes** | _any additional context_ |
-->
