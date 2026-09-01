---
name: task-brief
description: "Use only when the user explicitly invokes `$task-brief` or an active `$engineering-workflow` invokes it internally to produce a five-item task brief."
---

# Task Brief

Turn the conversation into a short, implementation-neutral engineering task definition. Use the information already present in the current conversation and repository; do not behave like a requirements-interview bot. When called internally by an active `$engineering-workflow`, this is the mandatory visible pre-routing stage.

## Output

Display exactly these five items, in this order:

```text
目标：                 requested outcome
当前上下文/证据：       relevant behavior, evidence, and repository area
约束与授权：            limits, authorization, compatibility, and safety boundaries
范围/非目标：           included scope and what must remain out of scope
验收标准/待确认项：     observable completion conditions and any material decisions to confirm
```

Fold references into `当前上下文/证据` and open questions into `验收标准/待确认项`; do not add a sixth visible heading.

Preserve explicit user wording such as “只分析”, “只做计划”, “不要修改文件”, or “只检查”. Do not invent requirements, implementation choices, tests, or success metrics. Mark genuinely unknown details as unknown or leave them open.

When invoked internally by `$engineering-workflow`, display the complete five-item brief and stop. Wait for a subsequent user response: confirmation proceeds to routing, a correction regenerates the complete brief and waits again, and an explicit cancellation stops the Workflow. Do not invoke `$task-router`, native Plan, or modify files during this wait. When explicitly invoked as `$task-brief`, return the five-item brief only and do not activate `$engineering-workflow` or `$task-router`.

Ask at most one question, and only when the missing answer would clearly change implementation direction, authorization, compatibility, data safety, or acceptance. Otherwise state the assumption briefly in `验收标准/待确认项` and let the confirmed `$task-router` or repository investigation resolve it. An explicit `$task-brief` request returns the brief without implementing the task.
