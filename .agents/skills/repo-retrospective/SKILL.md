---
name: repo-retrospective
description: "Use when a completed engineering task has user approval for an optional repository-environment retrospective about repeatable agent friction or a small durable improvement."
---

# Repository Retrospective

Perform a lightweight, evidence-based review of the repository environment after completed engineering work. This is an optional, user-confirmed closeout stage. The subject is agent-friendliness, not a retelling of the task, a generic project summary, or a second code review. The main Workflow always provides the task summary; this Skill only checks for durable repository-environment improvements.

## Entry and output handoff

Do not start this Skill automatically when implementation, verification, or Review finishes. The main Workflow must first show a completion card and wait for `进入复盘`; `跳过复盘` ends the task after the final summary. An explicit `$repo-retrospective` invocation is itself opt-in, but the same authorization and no-write boundaries still apply.

After the read-only review, report:

```markdown
**结论：复盘结果和候选改进已列出，等待你决定是否写入。**

**复盘结果：**
观察到的摩擦和证据，或“未发现可持久化问题”。

**建议去向：**
test/script/CI、AGENTS.md、Skill、docs，或“不变更”。

**下一步：**
说明是否确实提出一个小型、可持久化的改进。

**需要你确认：**
如果提出文件变更，是否允许写入。

**怎么回复：**
`确认写入`

> 实施候选改进

`只记录`

> 记录但不改文件

`取消`

> 结束复盘
```

如果没有候选改进，直接报告 `未发现可持久化问题` 并结束；不要为了产生改动而追问或补造问题。

Look for concrete friction such as repeatedly guessing test commands, unclear startup instructions, unstable environment-variable entry points, local/CI command drift, recurring special build flags, stale `AGENTS.md` rules, or a repeated manual reminder that could become a test or script.

Default to no changes. Persist an improvement only when all are true:

1. this task caused real rework, an error, or repeated investigation;
2. the friction is likely to recur; and
3. a short, stable change would materially reduce it.

Choose the narrowest durable home: machine-verifiable behavior belongs in a test, script, CI check, or stable command; lasting project rules belong in `AGENTS.md`; workflow-specific guidance belongs in a Skill; architectural background belongs in `docs`; and task-only state belongs in an ExecPlan. Do not save one-off paths, unverified guesses, temporary debugging notes, or routine task summaries.

Keep the user’s authorization mode. A `check-only` or `plan-only` task must not acquire write permission through the retrospective. Even for `implementation`, do not change files until the user confirms `确认写入` after seeing the evidence and destination. If the user chooses `只记录`, report the candidate without changing files. Record the evidence, chosen destination, user decision, and whether anything changed.
