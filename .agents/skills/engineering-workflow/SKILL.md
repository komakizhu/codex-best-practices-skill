---
name: engineering-workflow
description: "Use when the user explicitly invokes `$engineering-workflow` to summarize and route a repository engineering task; do not activate from an ordinary repository request, discussion, explanation, brainstorming, hypothetical design, read-only understanding, or pasted code."
---

# Engineering Workflow

This is a dormant, native-first entry point for repository engineering work. It is activated only by an explicit user invocation, first separates exploration, symptom-only Bug reports, and action-ready work, can match a suitable local discussion Skill, then coordinates task definition and routing before handing execution to the host’s native Codex capabilities and the repository’s `AGENTS.md`. The workflow is human-confirmed at consequential skill/native-stage handoffs; safe read-only discussion or RCA stages may be auto-invoked after a visible notice.

## Boundary

Activate the top-level Workflow when the user explicitly invokes `$engineering-workflow`; a direct invocation of one of the six public orchestration Skills enters the same Workflow contract at that named stage. A clear request to change, test, investigate, review, or otherwise perform a concrete action in the current repository does not activate either entry by itself. Do not activate for ordinary conversation, explanations, brainstorming, architecture discussion, hypothetical questions, read-only understanding, or pasted code without execution intent.

Once explicitly activated, keep this workflow active for the current engineering task through completion. Interpret urgency and implementation wording—such as “直接修”“马上做”“不要再问” or “跳过计划”—as task intent or authorization, never as permission to skip a required stage. End the active workflow early only when the user explicitly asks to exit, cancel, or stop using `$engineering-workflow`; do not treat an implicit change of tone as cancellation. The invocation itself does not grant write permission: the request still determines `implementation`, `check-only`, or `plan-only`.

## Public Skill stage entry and continuation

The six public orchestration Skills are stages of the same engineering Workflow. When a user directly invokes `$task-brief`, `$task-router`, `$rca-analyze`, `$option-explorer`, or `$repo-retrospective`, treat that invocation as entry at the named stage instead of treating the Skill as an isolated one-off answer. Preserve the stage’s own confirmation and no-write boundary, then show the next-stage handoff when the stage returns.

“Continue the full Workflow” means that the stage has a defined next handoff; it does not mean that Codex silently skips confirmation, escalates `check-only` or `plan-only` into implementation, or writes files. A direct public Skill invocation may skip only gates that belong to earlier stages. It must still show the current stage, the next stage, the user action or copyable command, and the consequence of waiting, continuing, or cancelling.

The default stage map is:

- `$task-brief` → `$task-router` after `确认`; `先聊一聊` returns to discussion.
- `$task-router` → read-only investigation, RCA, Option evaluation, or native Plan according to the route.
- `$rca-analyze` → `整理 brief` after a confirmed root cause; `只保留结论` is the explicit terminal branch.
- `$option-explorer` → native Plan or the filled manual Plan request after a direction is selected.
- native Plan → implementation only after the host’s Implement/return-to-execution action or the required execution confirmation.
- `$repo-retrospective` → the final repository-environment report; it is an optional terminal stage, not a new engineering stage.

Only the user’s explicit terminal wording (`只分析`, `只保留结论`, `只做计划`, or `取消`) may stop at the current stage. A stage may not stop merely because its local analysis is complete.

### Cross-turn continuation contract

Once the user explicitly invokes any public Workflow Skill, the Workflow remains active for that task across reply turns. The next user command is interpreted against the last visible card; the user does not need to invoke the next Skill again. The current stage must either render the next stage’s card directly or state a terminal boundary with a choice that explains its consequence. Reading another `SKILL.md` in a terminal is repository inspection, not a host-level Skill invocation and not a substitute for rendering the handoff.

Keep the six public Skills explicit-only (`allow_implicit_invocation: false`). This prevents ordinary repository requests from activating the Workflow while still allowing an explicitly selected stage to continue its own Workflow contract.

When the Workflow calls an external Skill, prepend a one-call instruction: keep that Skill’s technical and safety rules, start with the conclusion, split multiple facts into bullets, use subject-action-result Chinese, and return the result to the Workflow. The external Skill must not be edited and does not own the Workflow’s final handoff; the calling Workflow stage adds that handoff after the result returns.

When this Workflow temporarily calls an external Skill, start with the conclusion, use subject-action-result Chinese, and return the result to the Workflow; the external Skill must not be edited.

本次调用外部 Skill 时，先附加下面这段临时说明；它只影响本次调用，不会写入外部 Skill：

> 请保留你的专业判断、技术术语和安全边界。输出先写一句结论；有两个以上事实、风险或步骤时使用 bullet；每句话写清楚谁做什么、结果是什么。完成后把结果交还给当前 Workflow，不要替 Workflow 结束任务，也不要修改你的 Skill 文件。

## Intent gate

Before invoking `$task-brief`, classify the current conversation:

- **Exploration** — the user has a vague idea, says “先聊一聊”“帮我想想”“还没想好”“看看可不可行”, asks for discussion/brainstorming, or has not yet named an actionable repository change, check, or plan. Do not create or update a five-item brief. Native Plan is not an exploration tool.
- **Symptom-only Bug report / RCA-ready** — the user merely reports an unexpected behavior, failed test, regression, or inability to invoke a Skill, without explicitly asking to inspect, diagnose, investigate, explain, fix, change, implement, or complete it. Treat the report as read-only Bug review, not as implementation authorization and not as a Task Brief. Show the RCA notice below and enter `$rca-analyze`; do not route to `$task-brief` or `$task-router` first.
- **Explicit check-only** — the user explicitly asks to check, diagnose, investigate, review, or explain why something failed, and says not to modify or only report findings. Treat this as action-ready `check-only`: enter `$task-brief`, preserve the no-write boundary, and let `$task-router` choose the investigation size. RCA may be used inside that read-only investigation, but it is not the first route unless the user explicitly invokes `$rca-analyze`.
- **Action-ready** — the user explicitly asks for a repository outcome, including fixing, changing, implementing, or completing the reported Bug. Enter `$task-brief`. A Bug-fix request still carries a mandatory root-cause checkpoint before any write.
- **Mixed** — the user has a vague idea but also says “直接做/实现”. Do not guess whether to explore or execute; show a choice card and wait for `进入探索` or `整理 brief`.

Use the user’s intent, not the presence of the word “Bug”, to distinguish the three paths. “这里有个 Bug”“不能调用这个 Skill” are symptom reports. “请检查这个测试为什么失败，不要改代码”“帮我诊断原因，只报告结果” are explicit `check-only` requests. “修复这个 Bug”“补全这类 Skill 的调用规则并运行检查” are implementation requests. “看看这个 Bug，能不能顺便修” is still ambiguous; keep it in RCA/read-only mode until the user explicitly chooses a repair task.

For Mixed, use this compact choice card and stop:

```markdown
**结论：当前需求既包含探索意图，也包含实施请求。**

**当前判断：**
你还在想清楚方向，但同时也提到了要实施。

**下一步：**
你可以先把想法说清楚，也可以直接把需求整理成 action-ready Brief。

**需要你确认：**
请先决定是先讨论，还是直接定义任务；在你选择之前，Codex 不会进入 Route、Plan 或执行。

**怎么回复：**
`进入探索`

> 你想先讨论这个想法。Codex 接下来会帮你把目标和可能方向说清楚，不会修改文件。

`整理 brief`

> 你已经准备好进入任务定义。Codex 接下来会整理一份 Brief，并在你确认后再进入 Route。

`取消`

> 你要停止当前任务。Codex 不会继续处理。
```

If the user explicitly says `先聊一聊`, `还没想好`, `先别整理`, or equivalent at any point before the brief is confirmed, switch to Exploration immediately. Freeze any displayed brief as `暂存草案（未确认）`; do not regenerate it from each new message and do not treat later idea fragments as brief corrections.

For Exploration, show this short handoff and stop:

```markdown
**结论：当前先停留在探索阶段，不生成或更新 brief。**

**已完成：**
已识别出来，你现在是在探索方向，还没有确定要改哪些文件。

**下一步：**
你可以继续普通讨论，也可以选择「结构化探索」，让 Codex 按目标、场景、约束和候选方向逐步梳理。

**需要你确认：**
请选择探索方式；在你确认之前，Codex 不会进入 Route、Plan 或执行。

**怎么回复：**
`进入结构化探索`

> 你选择结构化探索。Codex 接下来会按目标、场景和约束逐步梳理，不会进入 Route 或修改文件。

`继续聊聊`

> 你想继续用普通对话补充想法。Codex 会继续讨论，不会更新 Brief、Route 或修改文件。

`整理 brief`

> 你要把已经讨论的内容整理成任务摘要。Codex 会根据当前讨论生成新的 Brief，然后请你确认。

`取消`

> 你要结束当前探索。Codex 不会进入 Route、Plan 或实施。
```

For a symptom-only Bug report / RCA-ready message, show this notice and then invoke `$rca-analyze` in the same response; this is a safe, read-only diagnostic stage and does not require a second confirmation:

```markdown
**结论：先确认故障证据和影响范围，当前不修改文件。**

**即将进入：**
Bug 审查 / RCA

**原因：**
当前只有故障现象，尚未明确授权修复；需要先确认复现、证据、根因和影响范围。

**边界：**
只读分析，不改文件；小 Bug 做聚焦 RCA，大 Bug 评估是否需要完整 RCA。

**切换：**
`整理 brief`

> 你要把已确认的 RCA 结果转成一项修复任务。Codex 会整理 Brief，但仍会保留后续 Route、Plan 和实施确认。

`只保留结论`

> 你只需要这次 RCA 的结论。Codex 会结束分析，不会修改文件。
```

For an explicit `check-only` request, show the normal five-item `$task-brief` instead; its no-write authorization is preserved through `$task-router`. After `$rca-analyze` returns, use the stage continuation handoff: show the RCA result, the next available action, and the exact command that selects it. The result does not grant write permission or silently enter implementation, but it must not disappear without a next-step or explicit terminal choice.

When Exploration is active, each response must add useful reasoning—such as a new hypothesis, trade-off, risk, example, or a focused next question—and may ask only one question at a time. Do not merely paraphrase the latest sentence and do not output a revised brief. If the user clearly asks to brainstorm, generate ideas, or compare possible directions, follow the Local Skill matching rules below; otherwise ordinary discussion stays ordinary discussion. When the user chooses `整理 brief`, summarize the accumulated conversation once through `$task-brief`, then use the normal five-item confirmation gate.

For Action-ready work, inspect the current conversation and repository context through `$task-brief` and display a five-item brief: `目标`, `当前上下文/证据`, `约束与授权`, `范围/非目标`, and `验收标准/待确认项`. Do not silently form or skip this brief when the task is Action-ready. The fifth item must end with the visible heading `请确认这份任务摘要。` and `$task-brief`'s exact four command-and-explanation blocks. Each command and each explanation must be a separate paragraph with a blank line between them. The explanation first states what the user's choice means, then what Codex will do next; do not replace it with terse internal-flow wording. Stop there. Do not invoke `$task-router`, native Plan, or modify files before confirmation. A post-brief response such as “确认”“按这个做” or “直接修” confirms only the brief and the requested authorization mode; `先聊一聊` is a mode switch, not a request to rewrite the brief, and no reply can bypass a later handoff or required native stage.

Keep the user’s authorization boundary intact. The workflow has exactly one mode: `implementation`, `check-only`, or `plan-only`. Never turn a check into a fix, or a plan into implementation.

## Public Skill surface

The only Skills named in normal user-facing callouts, handoffs, progress updates, and completion summaries are these six public orchestration Skills:

- `$engineering-workflow`
- `$task-brief`
- `$task-router`
- `$rca-analyze`
- `$option-explorer`
- `$repo-retrospective`

All other local Skills are internal helpers. They may provide the discussion or clarification behavior selected by this Workflow, but describe that behavior publicly as `结构化探索`、`逐项澄清` or `内部分析`; do not echo the helper’s Skill name or UI display name. This is an output-level allowlist. The local Skill metadata currently supports display names and invocation policy, but no supported `hidden` or `visibility` field; if the host itself renders a Skill chip or invocation event, do not claim that this rule hides that host chrome. If the user explicitly asks which helper is running, answer truthfully.

## Local Skill matching

After the Intent gate and before falling back to a brief or ordinary discussion, inspect the current session’s available local Skills and their frontmatter. Use only a Skill that is actually available; never invent an invocation or claim that a Skill ran unless its invocation succeeded. Local Skill matching does not grant implementation, file-write, native Plan, Router, Option, or retrospective authorization. The Bug report path is a named orchestration stage, not a replacement for intent matching: use `$rca-analyze` only for a symptom report or as an explicitly selected RCA prerequisite.

Use the clearest matching Skill, at most one at a time:

- **Idea exploration** — for “帮我想方案”“头脑风暴”“比较几个方向” or a vague idea where the user clearly asks for new directions, auto-invoke the available `头脑风暴` Skill. It is conversation-first and model-invocable; its own design-approval gate still applies, and any later design-document write or next Skill needs its own permission.
- **Relentless specification questions** — for “多问我”“逐个拷问”“把所有分支问清楚”, prefer the available model-invocable `grill-me` / `无代码库拷问` wrapper; if it is unavailable, use the model-invocable `拷问底层模式` fallback. Ask one question at a time, state the recommended answer, and wait for the user; the explicit request itself is the mode authorization.
- **User-only local Skills** — inspect the matched Skill’s own `disable-model-invocation: true` flag. Do not auto-invoke a disabled Skill or substitute another Skill while claiming it is the requested one. If the user names one, use a compact generic handoff and wait for its explicit entry; otherwise offer a model-invocable capability or ordinary discussion.

For an automatic local discussion Skill, show this notice before invoking it in the same response:

```markdown
**结论：当前进入讨论/澄清阶段，不更新 brief，也不执行变更。**

**即将进入：**
<公开的讨论方式>

**原因：**
你现在是想先讨论或澄清问题，还没有要求 Codex 修改代码或进入执行。

**边界：**
这一阶段只讨论和澄清，不更新 Brief、不进入 Route 或 Plan、不修改文件。如果后面需要写文档或调用其他 Skill，Codex 会单独说明并请你确认。

**切换：**
`继续聊聊`

> 你想离开当前的讨论方式，回到普通对话。Codex 会继续和你讨论，不会自动进入其他流程。

`停止当前 Skill`

> 你要停止当前的讨论方式。Codex 会结束这次讨论，不会继续调用它。
```

For an internal helper, `<公开的讨论方式>` must be a capability label such as `结构化探索` or `逐项澄清`, not the helper’s Skill name. The names of the six public Skills above may be shown when one of them is the actual next stage.

For a user-only Skill, use this handoff instead of trying to invoke it:

```markdown
**结论：当前需要你的明确入口，确认前不进入 Router、Plan 或执行。**

**已完成：**
已匹配到一个需要你亲自启动的本地辅助模式。

**下一步：**
等你说明要启动它，或者选择一个 Codex 可以自动调用的替代能力。

**需要你确认：**
请决定是否启动这条高强度或特定流程。

**怎么回复：**
`开始该模式`

> 你要启动这条流程。Codex 会按照该模式的规则继续，但仍会保留必要的确认和不写边界。

`用<可模型调用替代>`

> 你不启动这条用户专用流程，而是选择替代能力。Codex 会改用该能力继续。

`继续聊聊`

> 你想回到普通对话。Codex 会停在当前流程之外，不会启动该辅助模式。

`取消`

> 你要退出当前流程。Codex 不会启动该模式或修改文件。
```

Only when the user has already explicitly named a user-only Skill and needs an exact invocation string may the Workflow repeat that name; this exception is an entry instruction, not a normal progress label.

Do not emit this notice and then wait for a second confirmation when the user has already made the Skill intent explicit; that would turn automatic matching back into the missing handoff. For a merely possible match, or any Skill that is user-only, high-cost, writes a document, delegates work, or changes the conversation mode without explicit intent, use the four-line handoff and wait. Auto-starting a conversation-first Skill authorizes only its discussion phase; any later write, delegation, cost, or next-Skill transition still uses the applicable confirmation. After an internal local Skill returns, re-evaluate the intent. A direct public orchestration Skill is different: it already identifies the Workflow stage, so the Skill must return a stage handoff rather than requiring the user to rediscover the next stage from an isolated result.

## Handoff contract

Every permission-requiring transition from one Skill or native stage to another must use one visually scannable handoff card. Safe, model-invocable local discussion Skills may use the visible auto-call notice above when the user’s intent is explicit; all other transitions must state, in this order:

1. Start with one short, bold `**结论：...**` sentence containing the most important current decision, restriction, or user action.
2. Put each field label on its own bold line; put its detail on the following normal-text line or paragraph.
3. Show route metadata such as route, mode, type, and restrictions on separate lines rather than one semicolon-heavy sentence.
4. 每条回复命令必须单独一段，不使用列表符；命令与说明之间空一行，说明段必须以 `> ` 开头，让口令与说明明显分开；不用分号连接多个动作。

```markdown
**结论：一句话说明当前状态、限制或需要用户决定的事情。**

**已完成：**
已完成的阶段和证据。

**下一步：**
下一阶段或将执行的 native capability。

**需要你确认：**
需要用户确认的决定或权限。

**怎么回复：**
`确认`

> 你同意当前这一步。Codex 会继续处理这个阶段，但不会因此获得后续阶段的额外权限。

`修改：...`

> 你要补充或修改当前判断。Codex 会按照你的说明重新整理这张交接卡，然后再请你确认。

`继续聊聊`

> 你暂时不确认当前这张交接卡，想继续讨论。Codex 会保留当前内容，回到讨论，不会进入下一阶段或修改文件。

`取消`

> 你要停止当前流程。Codex 不会进入下一阶段，也不会修改文件。
```

Keep the card short enough to scan. Do not hide required evidence or constraints; move them into normal-text detail below the summary. Stop after a permission card. Do not silently invoke the named next stage. `确认` confirms only the current card; it is not blanket permission for later Option exploration, Plan approval, file writes, Worktree, Goal, Review, or retrospective. When the current card explicitly asks for plan execution, `执行` is accepted as a shorthand for `确认计划，执行`; an explicit host Implement action or return to execution mode is also execution authorization when the native Plan is visible. When the current card explicitly asks about closeout, `复盘` and `跳过` are accepted as shorthands for the named retrospective choices. `修改：...` revises the current handoff, and `取消` ends the active Workflow without starting the next stage.

### 真实回复正文

正文和交接卡使用同一套表达方式，不只调整可复制口令的格式：

- 第一段先说结论，随后分别说明已知事实、它意味着什么、下一步和边界。
- 每段只承担一个主要意思；出现两个以上并列原因、风险、文件或步骤时，用 bullet 拆开。
- 每个动作都写明主语。用“你”“Codex”“代码”“测试”或“宿主”说明谁做什么，不只写“已完成”“继续判断”。
- 保留 Brief、Route、RCA、Plan、Option、native Plan、implementation、Worktree、Goal、Review 等关键术语；第一次出现时用短句解释它在当前步骤中的用途。
- 把内部状态改写成用户能理解的决定和后果；不展示不会影响用户选择的内部流程细节。
- 需要复制的内容单独成段；口令后空一行，再用 `> ` 开头的段落解释选择结果。

### 轻量中文润色（humanizer-zh）

每次准备输出正文时，先保留技术事实，再做一轮轻量中文改写。只改表达，不改事实、权限、数值或结论：

- 固定术语保留 `Brief`、`Route`、`RCA`、`Plan`、`Option`、`native Plan`、`implementation`、`Review`、`Worktree`、`Goal`；普通的 `task`、`path`、`flow`、`handoff` 改成“任务”“处理逻辑/代码位置”“执行顺序”“下一步交接”。
- 技术标识符后面紧跟一句中文解释它具体做什么；不要把标识符或英文名词直接拼成中文复合词。
- 遇到两个以上抽象名词连在一起，改成“谁 + 做什么 + 结果”。例如把“键盘事务替换路径”改成“键盘输入的文本替换逻辑”。
- 每句话都写出主语和动作。把“问题集中在”“进入下一阶段”“完成判断”改成“代码在……时……”“你确认后，Codex 会……”。
- 删除没有机制支撑的形容词和机械连接词；如果半技术用户需要猜这句话是什么意思，就重写，不要继续堆术语。
- 输出前朗读一遍，确认开头先回答问题，后面再说明证据、影响、下一步和边界。

For the native Plan boundary, follow `$task-router`’s handoff. Never emit a bare or guessed `/plan` instruction. When the task requires native Plan and the host has no callable entry, immediately output a filled `Plan 请求` with the fixed field order `任务目标`、`已确认的 RCA/证据`、`范围`、`非目标`、`约束`、`验收与验证`, followed by `请只制定 native Plan，不修改文件、不执行实现、不提交。`, and tell the user to enter Plan through the host UI and paste it into the current conversation. Do not require prior confirmation that manual Plan exists and do not require a separate text acknowledgement after planning. Distinguish three observable states: the request has been shown, a real native Plan result is visible, and execution has been authorized either by the host’s Implement/return-to-execution action or, when no such action is observable, by `确认计划，执行`. A visible result needs no re-paste or upload. `update_plan` remains a checklist/progress tool, not native Plan.

An Exploration handoff is different from a task correction: `先聊一聊`/`进入探索` freezes the current brief, `进入结构化探索` explicitly selects the ideation capability, and `整理 brief` is the only reply that resumes task definition. If the user already clearly asks for brainstorming, the Workflow may auto-call it with the notice above; until a local Skill or ordinary discussion returns to action-ready intent, do not route, plan, write, or call Option Explorer. A local Skill’s later document or implementation step still needs the applicable confirmation.

After a confirmed handoff, routine read-only investigation, implementation, verification, and progress updates may continue within the selected route. Pause again for a consequential product, architecture, API, compatibility, data-loss, security, irreversible/costly decision, native capability requiring a user/UI action, or any explicit user request to wait.

## Composition

1. Apply the Intent gate and Local Skill matching before `$task-brief`. Clear requests for a safe, model-invocable discussion Skill may auto-call it with a notice; a symptom-only Bug report enters the read-only `$rca-analyze` path; an explicit `check-only` request gets the five-item brief with no-write mode; ambiguous exploration gets ordinary discussion or a handoff; only Action-ready work gets a five-item brief.
2. For Action-ready work, use `$task-brief` and stop for the explicit brief confirmation, correction, Exploration switch, or cancellation.
3. After brief confirmation, use `$task-router`. Display its route handoff and stop for `确认路由` (or `修改：...` / `继续聊聊` / `取消`) before investigation or any native stage. A direct `$task-router` invocation skips only the Workflow brief gate; it still receives this route handoff.
4. After the confirmed route’s necessary read-only investigation, explicitly report the Option trigger check. If all three Option conditions hold, stop and ask `进入 option`, `跳过 option`, or `继续聊聊`; never invoke `$option-explorer` silently. If the conditions do not hold, say `Option 不触发` and flow directly into the already-required next stage: invoke callable Plan, output the filled manual Plan request, or continue the confirmed Small route. Do not insert another text confirmation for a non-triggered optional branch.
5. Use `$option-explorer` only after `进入 option`. After exploration, stop with the candidates, trade-offs, recommendation, and exact next step; wait for `选择 A`, `选择 B`, `回到 Plan`, `继续聊聊`, or `取消`. A selected option authorizes the direction and the next required planning stage: invoke callable native Plan directly, or immediately output the filled manual Plan request. Do not add another text gate before the Plan input; selection never permits a file write by itself.
6. Execute the native stages required by the route. A Bug implementation of any size must complete a focused or full RCA and establish the root cause before the first file modification; a Small Bug may do this as the route’s minimal investigation, while a systemic Bug uses the `$rca-analyze` handoff or the route’s required deeper investigation. Small non-Bug implementation may proceed directly after the route handoff; Medium and Large implementation must complete the host’s actual native Plan before the first file modification. If native Plan is not callable, output the filled Plan request immediately, let the user enter Plan through the host UI, and do not write until the real result is visible. For `check-only` or `plan-only`, report the result and show the next available handoff or an explicit terminal choice; never ask for execution confirmation when that mode forbids implementation. For `implementation`, proceed when an explicit host Implement action or return to execution mode supplies authorization; otherwise show the concise plan handoff and wait for `确认计划，执行` (or `修改计划` / `取消`) before writing. For Large, include any proposed Worktree, Goal, ExecPlan persistence, migration, rollback, and milestone choices in that same execution handoff; ask separately only when a native capability requires a user/UI action. Never recreate Plan, Review, Goal, Worktree, Colleagues, or a test framework inside a Skill.
7. After implementation, real verification, and any required Review finish, display a completion handoff containing result, checks, review status, actual diff/status, and unresolved items. For Medium/Large work, stop and ask `进入复盘` or `跳过复盘`; do not invoke `$repo-retrospective` automatically. For Small work, offer it only when real recurring repository friction was observed or the user asks for it. The final task summary is always delivered; retrospective is an optional additional stage.
8. Follow `AGENTS.md` for real verification, `git status`, concise diff summary, and stopping. Never commit or publish automatically.

For `plan-only`, show a planning-end card after the Plan result. The card must contain `只保留方案`, `转成实施任务`, `继续聊聊`, and `取消`; `转成实施任务` starts a new Brief/Route authorization cycle and never writes files by itself.

This Skill does not implement planning, review, goals, worktrees, colleague orchestration, or a test framework. It connects the routing skills, can dispatch an available internal discussion helper under the rules above, presents explicit handoffs where permission matters, and preserves every Skill’s own boundaries.

For the Medium/Large closeout, use this compact card:

```markdown
**结论：实现和验证已完成，可选择是否进入复盘。**

**已完成：**
实现、真实验证、Review，以及 git status/diff 摘要。

**下一步：**
可选的 $repo-retrospective；最终任务摘要已经给出。

**需要你确认：**
是否检查可重复的仓库环境摩擦。

**怎么回复：**
`进入复盘`

> 你要检查这次任务是否暴露了可重复的仓库问题。Codex 接下来会进入复盘，但不会默认修改文件。

`跳过复盘`

> 你不需要进行复盘。Codex 会保留完成报告并结束当前任务。

`继续聊聊`

> 你想继续讨论完成结果。Codex 会保留完成报告，不会进入复盘或执行其他操作。

`取消`

> 你要停止当前 Workflow。Codex 不会进入复盘或继续其他操作。
```
