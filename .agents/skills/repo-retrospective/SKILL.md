---
name: repo-retrospective
description: "Use when a completed engineering task has user approval for an optional repository-environment retrospective about repeatable agent friction or a small durable improvement."
---

# Repository Retrospective

Perform a lightweight, evidence-based review of the repository environment after completed engineering work. This is an optional, user-confirmed closeout stage. The subject is agent-friendliness, not a retelling of the task, a generic project summary, or a second code review. The main Workflow always provides the task summary; this Skill only checks for durable repository-environment improvements.

## Entry and output handoff

Do not start this Skill automatically when implementation, verification, or Review finishes. The main Workflow must first show a completion card and wait for `进入复盘`; `跳过复盘` ends the task after the final summary. An explicit `$repo-retrospective` invocation is itself opt-in, but the same authorization and no-write boundaries still apply. This is the optional terminal stage of the engineering Workflow: it reports a repository-environment conclusion and does not silently start another engineering stage.

An explicit `$repo-retrospective` invocation starts this terminal stage directly. After the user chooses `只记录` or `取消`, show the consequence and end the Workflow. After `确认写入`, modify only the stated repository-environment target, verify it, and return the final result; do not silently start Brief, Route, Plan, or another Skill.

If this Workflow temporarily calls an external Skill while collecting retrospective evidence, keep that Skill’s own rules, ask it for conclusion-first subject-action-result Chinese, and return its result to this Skill. Do not modify the external Skill; this Skill owns the terminal handoff.

When this Workflow temporarily calls an external Skill, start with the conclusion, use subject-action-result Chinese, and return the result to the Workflow; the external Skill must not be edited.

After the read-only review, report the result and its terminal or write handoff. Do not return only a list of observations without telling the user what choice is available next.

After the read-only review, report:

```markdown
**结论：复盘结果和候选改进已列出，等待你决定是否写入。**

**复盘结果：**
Codex 已经列出观察到的仓库摩擦、对应证据和可能的长期改进；如果没有可重复的问题，会明确写出“未发现可持久化问题”。

**建议去向：**
候选改进适合放在 test/script/CI、AGENTS.md、Skill 或 docs；如果证据不足，建议“不变更”。

**下一步：**
如果确实存在可重复的摩擦，Codex 会提出一个范围很小、能够长期保留的改进；否则 Codex 会结束复盘。

**需要你确认：**
如果候选改进需要改文件，请确认是否允许 Codex 写入；在你确认前，复盘只读。

**怎么回复：**
`确认写入`

> 你同意实施已经说明的候选改进。Codex 接下来只修改对应范围，并运行相关验证。

`只记录`

> 你只想保留复盘记录。Codex 会记录候选改进，但不会修改文件。

`继续聊聊`

> 你暂时不决定是否写入，想继续讨论复盘结果。Codex 会保留当前复盘内容，回到讨论，不会修改文件。

`取消`

> 你要结束复盘。Codex 不会写入候选改进，也不会继续其他操作。
```

如果没有候选改进，直接报告 `未发现可持久化问题` 并结束；不要为了产生改动而追问或补造问题。

复盘正文先说结论，再分别说明观察、证据、建议去向和写入边界。每段都写清主语：用户决定是否写入，Codex 负责提出或实施候选改进，测试或脚本负责验证。保留 test/script/CI、AGENTS.md、Skill、docs 等关键术语；不把“实施候选改进”“结束复盘”单独当作完整说明。

轻量中文润色（humanizer-zh）：保留 test/script/CI、AGENTS.md、Skill、docs 等关键术语，但把普通英文和抽象名词改成具体动作。不要写“环境治理路径”“任务闭环”之类没有明确对象的词；改成“测试脚本会检查什么”“Codex 会把哪条规则写入哪个文件”。只改表达，不改证据、建议范围或写入权限。

Look for concrete friction such as repeatedly guessing test commands, unclear startup instructions, unstable environment-variable entry points, local/CI command drift, recurring special build flags, stale `AGENTS.md` rules, or a repeated manual reminder that could become a test or script.

Default to no changes. Persist an improvement only when all are true:

1. this task caused real rework, an error, or repeated investigation;
2. the friction is likely to recur; and
3. a short, stable change would materially reduce it.

Choose the narrowest durable home: machine-verifiable behavior belongs in a test, script, CI check, or stable command; lasting project rules belong in `AGENTS.md`; workflow-specific guidance belongs in a Skill; architectural background belongs in `docs`; and task-only state belongs in an ExecPlan. Do not save one-off paths, unverified guesses, temporary debugging notes, or routine task summaries.

Keep the user’s authorization mode. A `check-only` or `plan-only` task must not acquire write permission through the retrospective. Even for `implementation`, do not change files until the user confirms `确认写入` after seeing the evidence and destination. If the user chooses `只记录`, report the candidate without changing files. Record the evidence, chosen destination, user decision, and whether anything changed.
