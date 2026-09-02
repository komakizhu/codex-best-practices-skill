---
name: task-brief
description: "Use when the user explicitly invokes `$task-brief`, explicitly asks to整理 brief, or an active `$engineering-workflow` has identified action-ready work and invokes it internally to produce and confirm a five-item task brief."
---

# Task Brief

Turn action-ready conversation into a short, implementation-neutral engineering task definition. Use the information already present in the current conversation and repository; do not behave like a requirements-interview bot or a live conversation log. When called internally by an active `$engineering-workflow`, this is the mandatory visible pre-routing stage.

This Skill is a snapshot step, not the place to brainstorm or diagnose an unconfirmed Bug. It is appropriate when the user has asked to organize the idea into a task, when the Workflow intent gate has identified a concrete repository outcome, or when the user explicitly requests a read-only check/diagnosis. A symptom-only Bug report belongs in read-only `$rca-analyze`; an explicit `check-only` request enters this Skill with no-write authorization; an explicit Bug-fix request may enter this Skill but must carry the RCA requirement into `$task-router`. If the user says `先聊一聊`, `还没想好`, `先别整理`, `继续讨论`, or otherwise adds an exploratory idea instead of explicitly correcting the brief, do not regenerate the five items. Keep the last displayed brief as `暂存草案（未确认）`, return control to the Workflow's Exploration mode, and let the user choose ordinary discussion, `进入头脑风暴`, or `整理 brief` later. An exploratory fragment is not a `修改：...` instruction.

When another local exploration Skill is active, do not run Task Brief in parallel. Wait for that Skill's own handoff or for the user to say `整理 brief`; then synthesize the conversation once.

## Output

Display exactly these five items, in this order:

```text
目标：                 requested outcome
当前上下文/证据：       relevant behavior, evidence, and repository area
约束与授权：            limits, authorization, compatibility, and safety boundaries
范围/非目标：           included scope and what must remain out of scope
验收标准/待确认项：     observable completion conditions and any material decisions to confirm; end with the brief confirmation instructions
```

Fold references into `当前上下文/证据` and open questions into `验收标准/待确认项`; do not add a sixth visible heading.

When the brief follows RCA, include the confirmed symptom, reproduction/evidence, root cause, affected pattern, representative cases, and regression matrix in the first and fifth items as appropriate. Do not convert an unconfirmed theory into a requirement.

Preserve explicit user wording such as “只分析”, “只做计划”, “不要修改文件”, or “只检查”. Do not invent requirements, implementation choices, tests, or success metrics. Mark genuinely unknown details as unknown or leave them open.

When invoked internally by `$engineering-workflow`, display the complete five-item brief and end the fifth item with this unambiguous handoff: `请确认以上 brief；回复“确认”继续路由，回复“修改：...”重写完整 brief，回复“先聊一聊”冻结草案并进入探索，回复“取消”停止。` Stop. Wait for a subsequent user response: confirmation proceeds to `$task-router`, a correction regenerates the complete brief and waits again, `先聊一聊` freezes the snapshot and returns to Exploration mode, and an explicit cancellation stops the Workflow. Do not invoke `$task-router`, native Plan, or modify files during this wait. When explicitly invoked as `$task-brief`, return the five-item brief only and do not activate `$engineering-workflow` or `$task-router`; a standalone brief never grants routing or write authorization.

Ask at most one question, and only when the missing answer would clearly change implementation direction, authorization, compatibility, data safety, or acceptance. Otherwise state the assumption briefly in `验收标准/待确认项` and let the confirmed `$task-router` or repository investigation resolve it. An explicit `$task-brief` request returns the brief without implementing the task.
