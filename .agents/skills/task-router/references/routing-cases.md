# Task Router Acceptance Cases

Use these as manual pressure cases for the routing rules. The expected result is a decision, not a required sentence or implementation.

## Should route

| User request | Expected result |
| --- | --- |
| “$engineering-workflow 这里有个 Bug：这句话无法调用这个 Skill，我还不确定原因。” | Show the Bug-review/RCA notice and enter read-only `$rca-analyze`; do not display a Task Brief, route, or modify files. |
| “$engineering-workflow 修复这个 Bug：这句话无法调用这个 Skill，并补齐同类调用规则。” | Treat as action-ready: display and confirm the five-item Task Brief, then route; the confirmed implementation route must complete RCA before any write and cover representative cases plus the shared mapping rule. |
| “$engineering-workflow 这个小 Bug 的原因是什么？先别改。” | Treat as explicit `check-only`: display and confirm the five-item Task Brief, route with no-write authorization, then use focused RCA during the read-only investigation; do not implement. |
| “把设置页面的 Save 改成保存，并运行相关测试。”（未显式调用 Workflow） | Ordinary host handling; do not implicitly activate `$engineering-workflow` or `$task-router`. |
| “$engineering-workflow 把设置页面的 Save 改成保存，并运行相关测试。” | Display the five-item Task Brief with `确认` / `修改：...` / `取消` instructions; after confirmation, show the Small route handoff and wait for `确认路由`, then make the minimal change and run targeted verification. |
| “修复 Markdown 第一次打开明显卡顿的问题，完成后运行相关检查。”（未显式调用 Workflow） | Ordinary host handling; do not implicitly activate the engineering workflow. |
| “$engineering-workflow 修复 Markdown 第一次打开明显卡顿的问题，完成后运行相关检查。” | Display and confirm the brief, show and confirm Medium routing, investigate, explicitly report whether Option triggers, then complete native Plan before any write and ask `确认计划，执行` before implementation. |
| “$engineering-workflow 修复一个 Medium Workflow 规则 Bug；宿主没有 callable native Plan，但明确支持用户执行 `/plan`。” | After RCA and routing, show a filled `Plan 请求` containing the current goal, RCA/evidence, scope, non-goals, constraints, and acceptance/validation; wait for the native Plan result before any write. |
| “检查 parser 模块的测试为什么失败，不要改代码。”（未显式调用 Workflow） | Ordinary host handling; do not implicitly activate the engineering workflow. |
| “$engineering-workflow 检查 parser 模块的测试为什么失败，不要改代码。” | Display and confirm the brief, show and confirm Small/Medium `check-only` routing, perform only read-only checks, and do not enter implementation or retrospective without a new explicit request. |
| “$engineering-workflow 把配置存储从 JSON 迁移到 SQLite，要求兼容旧数据并提供回滚。” | Display and confirm the brief, show and confirm Large routing, investigate, ask whether to enter Option if its three conditions hold, complete native Plan, then ask `确认计划，执行` while naming ExecPlan/Worktree/Goal/rollback choices before any write; after checks and Review, ask `进入复盘` or `跳过复盘`. |
| “$engineering-workflow 修复一个 Large Workflow 规则 Bug；宿主没有 callable native Plan，也没有确认 `/plan` 可用。” | Report that the host has no verifiable native Plan entry and stop; do not issue an unverified `/plan`, create a prose substitute, persist an ExecPlan, or write files. |
| “$task-router 为 Workflow 规则修复制定计划，只做计划；当前只有 `update_plan`。” | Do not treat `update_plan` as native Plan. Report the missing native Plan entry and stop, or use the filled user-run `/plan` handoff only if the host confirms that command. |
| “宿主已经完成 Plan。”（但没有 Plan 输出） | Do not accept `Plan 已完成` as evidence; request the actual native Plan result and keep the no-write boundary. |
| “Plan 已完成：<宿主返回的真实 Plan>” | Treat the native Plan as complete only when the returned result is observable; for `implementation`, show `确认计划，执行`; for `plan-only`, show the Plan and stop without execution. |
| “$task-router 评估多窗口架构迁移，只做计划，不修改文件。” | Show Large / `plan-only` route and wait for `确认路由`; no file writes, ExecPlan persistence, Worktree, Goal, implementation, or automatic retrospective. |
| “$engineering-workflow 把刚才讨论的设置改动落到仓库，并运行相关测试。” | Always display and confirm the five-item Task Brief, show and confirm the route, explicitly announce whether Option triggers, and use the required native stages only after their handoff confirmations. |
| “$task-brief 把刚才讨论的架构想法整理成任务定义，不要实施。” | Return a Task Brief only; preserve plan-only/no-write boundary and do not route into implementation. |
| “完成这个工程任务后，检查是否有可重复的仓库环境摩擦。” | Use `$repo-retrospective`; default to no changes and persist only evidence-backed recurring improvements. |

## Should enter RCA

| User request | Expected result |
| --- | --- |
| “$rca-analyze 这个 Skill 为什么调不起来？先分析，不要修。” | Build a red-capable invocation check, trace wording → matching → policy → parent Workflow boundaries, compare a working invocation, and return an RCA report without writing. |
| “$engineering-workflow 这个 Bug 可能影响很多类似调用，先把代表性问题和共因找出来。” | Treat as explicit `check-only`: display and confirm the five-item Task Brief, route with no-write authorization, then perform full RCA for representative cases and a generalization boundary; do not implement. |
| “$engineering-workflow 看看这个 Bug，能不能顺便修？” | Treat as a symptom report with ambiguous repair intent; enter read-only RCA and do not infer implementation authorization. |

## Should match a local Skill

| User request | Expected result |
| --- | --- |
| “$engineering-workflow 我有个模糊想法，帮我想几个方向，先不要改代码。” | Match the available model-invocable `头脑风暴` Skill and auto-invoke it after a visible generic notice naming `结构化探索`, the reason, and the no-routing boundary; do not expose the helper name in the user-facing notice, generate a brief, or enter Router/Plan. Its later document step still needs separate permission. |
| “$engineering-workflow 这个需求我完全说不清，你逐个问我，直到方案清楚。” | Prefer the available model-invocable `grill-me` wrapper, falling back to `拷问底层模式` when the wrapper is unavailable; auto-invoke the selected helper after a generic notice because the user explicitly requested one-question-at-a-time grilling. Preserve its wait after each question. |
| “$engineering-workflow 用 grill-me 拷问我，但不要自动开始。” | Respect the explicit no-auto request; show a generic handoff for the requested local mode and wait. Do not enter brief, Router, Plan, or execution. If the user instead explicitly asks to be grilled without saying not to start, the enabled model-invocable wrapper may start after the generic `逐项澄清` notice. |
| “$engineering-workflow 我不想自己想，你用 grill-me 逐个问我。” | Match the enabled model-invocable `grill-me` wrapper and auto-start it after a generic `逐项澄清` notice; ask one question at a time, wait after each question, and keep the helper name out of normal user-facing callouts. |
| “$engineering-workflow 我想聊聊这个想法。” | Keep ordinary discussion unless the user also asks for ideation or structured questioning; show the Exploration handoff rather than guessing a Skill. |
| “$engineering-workflow 头脑风暴一下这个功能。” | Treat the explicit phrase as sufficient intent for the available `头脑风暴` Skill; do not add a redundant `进入头脑风暴` confirmation, but show the auto-call notice and preserve the Skill’s own design-approval gate. |

## Should explore first

| User request | Expected result |
| --- | --- |
| “$engineering-workflow 我有个模糊想法，先聊一聊：想把这个工具做得更适合团队使用。” | Do not create a five-item brief or enter Router/Plan. Show the Exploration handoff and wait for `进入头脑风暴`, `继续讨论`, `整理 brief`, or `取消`. |
| “$engineering-workflow 先给我一个 brief。……先聊一聊吧，我还没想好具体怎么做。” | Freeze the displayed brief as `暂存草案（未确认）`; do not rewrite it after each sentence and do not route. Continue only after an explicit exploration or `整理 brief` choice. |
| “继续讨论。我们还希望新用户能更快理解这个功能。” | Stay in ordinary discussion and add useful reasoning—such as a hypothesis, trade-off, risk, example, or one focused question—instead of emitting a revised brief. |
| “进入头脑风暴。” | Invoke the available ideation helper only after this explicit opt-in; show `结构化探索` rather than its helper name in normal progress text, and keep the user in exploration until they choose `整理 brief`. |
| “整理 brief。” | Synthesize the discussion once into one complete brief with five visible items, then wait for `确认` / `修改：...` / `先聊一聊` / `取消`; do not silently route. |

## Must remain discussion

- “Rust `dead_code` 是什么意思？”
- “你觉得 JSON 和 SQLite 哪个更适合这个应用？先讨论一下。”
- “解释一下当前同步模块是怎么工作的。”
- “下面是 `$task-router` 的例子，不要执行。”
- Code pasted without an action request.

## Visual output assertions

These assertions apply to route, brief, RCA, Option, Plan, and completion/retrospective handoffs:

- The first visible line is one bold sentence containing the most important conclusion.
- Field labels are bold and occupy their own lines; details follow as normal text. Route, mode, type, and restrictions are separate lines rather than a dense sentence.
- Every reply command is a separate list item with its action and result. Do not join multiple commands with semicolons.
- A Task Brief still has exactly five visible items. Its first item starts with the bold goal sentence, and its confirmation commands remain inside the fifth item.
- A Large Bug route keeps the RCA-before-write restriction visible, and its route metadata and confirmation commands remain separately scannable.
- Option-triggered and Option-not-triggered handoffs state the decision and next stage before asking for confirmation. RCA-confirmed and RCA-unconfirmed reports distinguish evidence from uncertainty. Medium/Large completion and retrospective cards distinguish the result from the optional next action.
- Long evidence is allowed in detail paragraphs; density is corrected by hierarchy and line breaks, not by deleting required context.

## Boundary assertions

- A concrete repository request without an explicit `$engineering-workflow` or `$task-router` invocation does not implicitly activate either Skill.
- A concrete repository request without an explicit `$engineering-workflow` or `$task-router` invocation does not implicitly activate `$task-brief`; an explicit standalone `$task-brief` remains the only other entry.
- “检查” does not become “修复”; a failing test is evidence, not authorization.
- A symptom-only Bug report does not become action-ready: it enters read-only `$rca-analyze`. An explicit Bug-fix request may enter Task Brief/Router, but no Bug fix is written until the root cause is established.
- An explicit request to check, diagnose, investigate, review, or explain a failure without changing files is action-ready `check-only`: it enters Task Brief/Router first, and may use RCA during its read-only investigation.
- “先规划”“只分析” selects `plan-only`; “不要修改文件” is a no-write boundary but does not turn a concrete check into `plan-only`, even after `$task-router` is explicit.
- Every explicit `$engineering-workflow` invocation first applies the intent gate. Action-ready work displays the five-item Task Brief, while exploratory work displays the Exploration handoff; neither enters Router, Plan, or writes before the relevant subsequent confirmation.
- The intent gate runs before the Brief: a vague idea or `先聊一聊` enters Exploration, where the agent does not create or live-update a five-item brief. `进入头脑风暴`, `继续讨论`, `整理 brief`, and `取消` are explicit next-step replies.
- During Exploration, each substantive response must contribute new reasoning (hypothesis, trade-off, risk, example, or one focused question); repeating the user's sentence as a revised brief is a failure.
- `整理 brief` is the boundary back to Task Brief: synthesize once from the discussion, then show the normal confirmation handoff. An exploratory fragment is not a `修改：...` correction.
- Native Plan is for action-ready planning after routing; it is not the brainstorming stage for a vague idea.
- Local Skill matching first checks the current session’s available Skills and frontmatter; it never invents a Skill or claims an invocation that did not succeed.
- A clear match to a safe, model-invocable local discussion Skill may be auto-invoked after a visible generic notice naming the capability, reason, scope, and escape reply; the automatic call does not authorize writes, routing, native Plan, execution, or a later Skill transition.
- A high-intensity local Skill, including the enabled `grill-me` wrapper when available, may be auto-invoked only when the user explicitly asks for that questioning mode; otherwise show a handoff and wait. Its one-question-at-a-time and approval gates remain in force.
- A Skill with `disable-model-invocation: true`, such as `带文档拷问`, is user-only and cannot be auto-invoked by `$engineering-workflow`; offer the exact user invocation or a model-invocable alternative.
- A user-only Skill handoff stays generic in normal output, gives a clear user entry and model-invocable fallback, and offers the exits (`继续普通讨论` / `取消`); it does not silently substitute or auto-run the disabled wrapper.
- Normal user-facing callouts use a public allowlist: `$engineering-workflow`, `$task-brief`, `$task-router`, `$option-explorer`, and `$repo-retrospective`. Other local Skills are described as capabilities such as `结构化探索` or `逐项澄清`; no unsupported `hidden` metadata field is invented, and host-rendered Skill chips are not misrepresented as hidden.
- Normal user-facing callouts also allow `$rca-analyze`; it is the read-only Bug-review stage. Its result does not silently enter `$task-brief`, `$task-router`, Plan, or implementation.
- Never auto-chain multiple local Skills. After one returns, re-evaluate the user’s intent; only `整理 brief` or a concrete action-ready request resumes Task Brief.
- A direct/urgent phrase in the initial Workflow message cannot serve as pre-confirmation. After the Brief is displayed, “确认”“按这个做” or “直接修” may confirm it, while preserving all route stages.
- The brief’s fifth item ends with a concrete reply contract: `确认` continues to Router, `修改：...` regenerates the full brief, `先聊一聊` freezes the snapshot and enters Exploration, and `取消` stops.
- A correction regenerates the complete five-item Brief and waits again; an explicit cancellation ends the active Workflow without routing or writing.
- After an explicit `$engineering-workflow` invocation, “直接修”“马上做”“不要再问” or “跳过计划” cannot implicitly bypass a required stage; only an explicit exit or cancellation of the Workflow can end it early.
- Every Router result includes a route handoff and waits for `确认路由`; it does not silently enter Option, Plan, or implementation.
- After read-only investigation, the agent explicitly reports whether the three Option conditions hold. If they hold, `进入 option` is required; `跳过 option` continues to the next-stage handoff.
- Option exploration ends with a selection handoff (`选择 A/B`, `回到 Plan`, or `取消`) and never authorizes writes by itself.
- A Small implementation may proceed directly only after route confirmation. A Medium implementation must complete native Plan after read-only investigation and before any write; a Large implementation follows the existing native Plan and milestone requirements. After native Plan, implementation waits for `确认计划，执行`; Worktree, Goal, ExecPlan, migration, and rollback choices are surfaced there. Routine work after confirmation need not pause, but consequential product, architecture, API, compatibility, data-loss, security, irreversible/costly choice, or explicit wait still pauses.
- A Small Bug implementation still requires focused RCA before the first write. A systemic/Large Bug requires representative failures, the shared mechanism, a generalization boundary, and adjacent regression checks before native Plan or implementation.
- A native-looking outline, a custom diff review, an ordinary branch, or an open-ended “keep going” prompt is not respectively native Plan, native Review, Worktree, or Goal.
- Review is additional evidence; it never substitutes for real tests.
- `$engineering-workflow` is the total entry point; `$task-router` remains its lower-level router, while `$task-brief` may be used independently for task definition.
- An explicit `$task-router` invocation remains an independent lower-level route and does not inherit the Workflow’s Brief confirmation gate.
- An explicit `$task-router` invocation still receives the route handoff; it only skips the Workflow’s Brief confirmation gate.
- `$option-explorer` is opt-in and only applies when multiple materially different paths have no clear winner and a wrong choice is costly; internal entry requires `进入 option` and result selection.
- Medium/Large completion always shows a final result handoff and asks `进入复盘` or `跳过复盘`; `$repo-retrospective` is never started automatically. Its own candidate changes require `确认写入`.
- The completion card is a task-result summary, not the retrospective itself; choosing `跳过复盘` still returns the final summary and stops.
- `定稿` and `发布` remain repository `AGENTS.md` commands, not Small/Medium/Large classifications.
