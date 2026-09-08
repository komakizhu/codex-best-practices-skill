---
name: task-brief
description: "Use when the user explicitly invokes `$task-brief`, explicitly asks to整理 brief, or an active `$engineering-workflow` has identified action-ready work and invokes it internally to produce and confirm a five-item task brief."
---

# Task Brief

Turn action-ready conversation into a short, implementation-neutral engineering task definition. Use the information already present in the current conversation and repository; do not behave like a requirements-interview bot or a live conversation log. When called internally by an active `$engineering-workflow`, this is the mandatory visible pre-routing stage.

This Skill is a snapshot step, not the place to brainstorm or diagnose an unconfirmed Bug. It is appropriate when the user has asked to organize the idea into a task, when the Workflow intent gate has identified a concrete repository outcome, or when the user explicitly requests a read-only check/diagnosis. A symptom-only Bug report belongs in read-only `$rca-analyze`; an explicit `check-only` request enters this Skill with no-write authorization; an explicit Bug-fix request may enter this Skill but must carry the RCA requirement into `$task-router`. If the user says `先聊一聊`, `还没想好`, `先别整理`, `继续讨论`, or otherwise adds an exploratory idea instead of explicitly correcting the brief, do not regenerate the five items. Keep the last displayed brief as `暂存草案（未确认）`, return control to the Workflow's Exploration mode, and let the user choose ordinary discussion, `进入头脑风暴`, or `整理 brief` later. An exploratory fragment is not a `修改：...` instruction.

When another local exploration Skill is active, do not run Task Brief in parallel. Wait for that Skill's own handoff or for the user to say `整理 brief`; then synthesize the conversation once.

## 每条回复的下一步和写入边界

只要当前 Workflow 仍在运行，Task Brief 的每条可见回复都要写清楚当前结论、Codex 已完成什么、下一步由谁执行和当前边界。等待用户选择时才提供口令或宿主动作；交接卡展示 3～4 个当前场景真正需要的不同选项，不重复同义口令。Codex 正在继续的进度回复要明确写出正在执行的动作，不要求用户回复；受阻时说明阻塞原因和解除条件；真正完成时说明完成范围和遗留事项，不制造额外确认循环。Brief 保持下面固定的五项格式；它不重复添加公共标题，但必须在五项内容和确认说明中表达这些信息。讨论回复和侧边结果仍遵守完整交接规则，不能只给摘要就结束。当环境尚未准备好而必须等待时，只显示 `已就绪`、`继续聊聊`、`取消`；用户回复 `已就绪` 后，Codex 继续实际的只读动作，不要求重复确认。

用户选择 `先聊一聊` 后，Codex 必须把当前 Brief 标记为未确认草案并立即进入 `discussion`、`no-write` 状态。Codex 要暂停或取消已经排队的写入；在用户重新确认 Brief、Route 和后续授权前，不得产生 `FileChange`。每次写文件前，Codex 都要重新检查最新模式和授权。

如果收到 `SIDE-HANDOFF`，Task Brief 只能把侧边结果当作事实。Codex 必须在主会话重新整理 Brief，并显示标准的下一步交接卡；侧边结果不能直接改写 Brief、跳过确认或授予写入权限。

## Output

Display exactly these five items, in this order. Use Markdown so the first line is easy to scan; keep the confirmation choices inside the fifth item instead of adding a sixth heading:

```markdown
**目标：一句话概括要达成的结果。**

**当前上下文/证据：**
相关行为、证据和仓库范围。

**约束与授权：**
限制、授权、兼容性和安全边界。

**范围/非目标：**
包含的范围，以及明确不做的内容。

**验收标准/待确认项：**
可观察的完成条件，以及需要确认的关键决定。

下一步由你确认这份任务摘要；你确认后，Codex 会展示 Route，但在后续授权前不会修改文件。

请确认这份任务摘要。

`确认`

> 你同意这份任务摘要。Codex 接下来会判断这个任务应该进入哪条工作流程，但不会因此直接修改文件。

`修改：请把……改成……`

> 你不同意当前的任务摘要。Codex 会按照你写的要求重新整理完整摘要，然后再次请你确认。

`先聊一聊`

> 你暂时不确认这份任务摘要，想先继续讨论。Codex 会保留当前摘要作为未确认草案；讨论期间不会进入任务路由、Plan 或实施。等你明确说 `整理 brief` 后，Codex 才会重新整理摘要并再次请你确认。

`取消`

> 你要停止当前任务。Codex 不会继续路由、规划或实施。
```

Fold references into `当前上下文/证据` and open questions into `验收标准/待确认项`; do not add a sixth visible heading. The fifth item must state who acts next and what the current boundary is.

## 真实回复写作规则

Brief 的正文不是字段值的堆叠，而是让用户快速看懂“要解决什么、目前知道什么、接下来谁做什么”。遵循以下规则：

- 先写一句明确结论，再补充证据、限制、范围和验收条件。
- 每段只回答一个主要问题；有两个以上并列事实时，用 bullet 拆开。
- 每个动作都写清主语，例如“你确认后，Codex 会……”“测试会验证……”“代码需要……”。不要只写“已完成”“进入下一阶段”。
- 保留 Brief、Route、RCA、Plan、Option 等关键术语；第一次出现时，用一句短话说明它在当前步骤中的作用。
- 把内部流程状态翻译成用户能做的选择，不把“继续路由”“状态已冻结”等内部说法直接当作正文。
- 口令和说明继续使用独立段落；说明以 `> ` 开头，确保复制口令时不会把解释一起带走。

轻量中文润色（humanizer-zh）：保留 `Brief` 这个固定名称，但把普通的 `task`、`path`、`flow`、`handoff` 说成“任务”“处理逻辑/代码位置”“执行顺序”“下一步交接”。技术标识符后面说明它具体做什么；遇到“键盘事务替换路径”这类抽象名词堆叠，改成“键盘输入的文本替换逻辑”。每句话写清主语和结果，只改表达，不改事实、权限、数值或结论。

When the brief follows RCA, include the confirmed symptom, reproduction/evidence, root cause, affected pattern, representative cases, and regression matrix in the first and fifth items as appropriate. Do not convert an unconfirmed theory into a requirement.

Preserve explicit user wording such as “只分析”, “只做计划”, “不要修改文件”, or “只检查”. Do not invent requirements, implementation choices, tests, or success metrics. Mark genuinely unknown details as unknown or leave them open.

When invoked internally by `$engineering-workflow`, display the complete five-item brief and end the fifth item with the exact four command-and-explanation blocks above. Use `请确认这份任务摘要。` as the visible heading. Each command and each explanation is its own paragraph, separated by one blank line; every explanation paragraph must start with the Markdown blockquote marker `> `. Do not shorten the explanations into internal-state labels such as `继续路由`, `重写 brief`, or `停止`. The explanation must first say what the user's choice means and then say what Codex will do next. Stop and wait for a subsequent user response. Do not invoke `$task-router`, native Plan, or modify files during this wait.

When the user directly invokes `$task-brief` for an action-ready repository task, treat the Brief as the first stage of the full Workflow. `确认` continues to `$task-router` after this handoff; it does not authorize implementation by itself. If the user explicitly asks for a standalone Brief or uses a terminal mode such as `只整理 brief`, return the five-item brief and stop at the stated boundary.

The continuation is a Workflow handoff, not a request for the user to invoke another Skill manually. After the user replies `确认`, the next response must visibly be a Route card. If the host does not provide a callable Skill entry, the current Workflow still renders the Route card using the installed routing rules; reading a `SKILL.md` file in a terminal is repository inspection, not evidence that the host performed a second Skill invocation.

After `先聊一聊` or `继续聊聊`, every discussion response must still end with a clear choice such as `继续聊聊`, `整理 brief`, or `取消`, followed by a `> ` explanation. Discussion is a pause overlay, not a new authorization mode: Codex keeps the existing Brief, Route, Plan, and authorization records, blocks writes while paused, and checks whether the scope changed before resuming. Discussion is not a hidden pause: Codex must tell the user what will happen next and must not write files while the discussion mode is active.

If this Workflow temporarily calls an external Skill while preparing the Brief, keep the external Skill’s own rules, ask it for conclusion-first subject-action-result Chinese, and return its result to this Workflow. Do not modify the external Skill; this Skill remains responsible for the Brief and its next-stage handoff.

When this Workflow temporarily calls an external Skill, start with the conclusion, use subject-action-result Chinese, and return the result to the Workflow; the external Skill must not be edited.

Ask at most one question, and only when the missing answer would clearly change implementation direction, authorization, compatibility, data safety, or acceptance. Otherwise state the assumption briefly in `验收标准/待确认项` and let the confirmed `$task-router` or repository investigation resolve it. An explicit `$task-brief` request returns the brief without implementing the task.
