---
name: task-brief
description: "Use when a repository request is spread across earlier conversation, expressed informally, or missing a concise shared task definition."
---

# Task Brief

Turn the conversation into a short, implementation-neutral engineering task definition. Use the information already present in the current conversation and repository; do not behave like a requirements-interview bot.

## Output

```text
Goal:      what outcome is requested
Context:   relevant current behavior, evidence, and repository area
Constraints: explicit limits, authorization, compatibility, and safety boundaries
Non-goals: what must remain out of scope
Acceptance: observable conditions that mean the task is complete
References: optional files, commands, issues, or prior decisions
Open Questions: optional; only questions that can materially change the route
```

Preserve explicit user wording such as “只分析”, “只做计划”, “不要修改文件”, or “只检查”. Do not invent requirements, implementation choices, tests, or success metrics. Mark genuinely unknown details as unknown or leave them open.

Ask at most one question, and only when the missing answer would clearly change implementation direction, authorization, compatibility, data safety, or acceptance. Otherwise state the assumption briefly and let `$task-router` or repository investigation resolve it. A brief may be formed internally by `$engineering-workflow`; an explicit `$task-brief` request should return the brief without implementing the task.
