---
name: task-router
description: "Use when the user explicitly invokes `$task-router` or an active `$engineering-workflow` invokes it internally to route an authorized repository task; do not activate from an ordinary repository request, discussion, explanation, brainstorming, hypothetical design, read-only understanding, or pasted code."
---

# Task Router

This is the lower-level router used internally by an active `$engineering-workflow` (and available for explicit direct use). It is a dormant, native-first intake router—not an engineering framework. It only gates authorization, classifies scope, and selects an existing Codex-native workflow. Once routed, the native workflow and the repository’s applicable `AGENTS.md` rules own execution and completion.

## Gate

Activate only for an explicit `$task-router` invocation or an internal call from an already active `$engineering-workflow`. A clear request to change, test, investigate, review, or otherwise perform a concrete action in the current repository does not activate this router by itself. If intent is ambiguous, stay in discussion mode. Read the root and applicable path-specific `AGENTS.md` files before repository work; they outrank this skill. Do not copy their policies into this skill or invent a replacement when one is absent.

An active `$engineering-workflow` invocation keeps this router available for its current engineering task. Urgency or implementation wording cannot implicitly bypass the selected route or its required native stages; only an explicit cancellation of the active Workflow can end that governing contract early.

When called internally by `$engineering-workflow`, this router requires a confirmed five-item Task Brief from the current task. If the brief has not been displayed and confirmed, return to the Task Brief stage without classifying, invoking native Plan, or modifying files. A user’s explicit direct `$task-router` invocation enters the Workflow at the Route stage and may skip only the earlier Brief gate; it still receives the Route handoff and all later investigation, Option, Plan, and execution boundaries.

For a routed task, choose exactly one authorization mode before classifying. A discussion-only message has no mode, size, route line, or native workflow.

- `implementation`: the user asked to modify the repository.
- `check-only`: the requested deliverable is a check, test, investigation, review, or diagnosis without a fix. “Do not modify” reinforces this boundary but does not turn a concrete check into planning. Findings do not grant write permission.
- `plan-only`: the requested deliverable is analysis, planning, or design only, or the user explicitly says to plan without implementation. A no-write instruction is binding, but by itself does not determine the mode.

If a user requests implementation while also forbidding writes, preserve the no-write boundary and explain the conflict; do not silently implement or relabel the request. Do not pause for routine approval during an already-confirmed implementation stage; pause at the explicit handoff cards and for a consequential product, architecture, API, compatibility, data-loss, security, irreversible/costly choice, or an explicit request to wait.

## Bug root-cause gate

Separate a symptom report from a repair request before routing:

- A symptom-only report with no explicit request to inspect, diagnose, investigate, explain, or repair is RCA-ready, not an action-ready task. Return it to the active Workflow’s `$rca-analyze` path, or ask the user to invoke `$rca-analyze` when no Workflow is active; do not create a repair route from the report alone.
- An explicit request to check, diagnose, investigate, review, or explain a failure while not modifying files is `check-only`. It may use RCA as the read-only investigation method, but it enters `$task-brief` and `$task-router` first so the no-write scope and investigation size are visible.
- An explicit Bug-fix request is `implementation`, but the authorization covers the repair task—not a guessed fix. Root-cause analysis is mandatory before the first file write for Small, Medium, and Large Bugs.
- For a Small Bug, the route’s minimal investigation must still record the exact symptom, a red-capable reproduction or equivalent evidence, the failing call path, the confirmed cause, and the focused regression check. Only then may the smallest repair be written.
- For a systemic or Large Bug, use the full RCA protocol: identify representative failures, trace the shared mechanism, compare working and broken cases, and define the general rule plus adjacent regression matrix. Do not patch one reported example and call the investigation complete.

If the route needs the separate `$rca-analyze` Skill, show a Skill handoff and wait; do not silently invoke it or leave the route without a return path. A route may perform its own read-only RCA investigation when that is sufficient and observable. In either form, a plausible theory, a failing test, or a user’s “应该是这里” is not a confirmed root cause.

After a Bug route’s read-only investigation, report the RCA state explicitly. If the root cause is still unconfirmed, continue evidence gathering or ask for the missing artifact; do not enter Option, native Plan, or implementation as though the cause were known. Once it is confirmed, show the next-stage handoff before continuing.

## Classify

Use uncertainty, impact, risk, reversibility, compatibility, migration/security concerns, milestones, and validation complexity—not file count or line count.

- **Small**: the method is clear, the change is narrow and low-risk, and verification is direct.
- **Medium**: the root cause or call path needs investigation, or the bounded work affects multiple modules, behavior, performance, concurrency, or ordinary refactoring.
- **Large**: the work changes persistence or formats, core architecture, public APIs/protocols, multiple subsystems, data/security boundaries, rollback strategy, or requires milestones, long-running work, or cross-session progress.

For `check-only`, classify the investigation itself: a directly reproducible failure in one area can be Small, while an unknown call path, multiple modules, environment interaction, or complex evidence trail is Medium or Large. The no-write boundary changes the mode, not the size.

Emit one concise route summary and one handoff card before routed work, in the user’s language where practical. Put the summary first, then show route metadata and handoff details as separate visual blocks:

```markdown
**结论：先做必要的只读调查；调查后再检查是否触发 Option。**

**路由：** Medium
**模式：** implementation
**类型：** 普通工程任务

**已完成：**
Brief 已经确认，Codex 也已经判断了这次任务是否需要写文件以及调查多大的范围。

**下一步：**
先查清问题的调用链和现有证据，再判断是否需要进入 Option 比较方案。

**需要你确认：**
请确认是否按这条 Route 继续；你确认后，Codex 才会开始只读调查。

**怎么回复：**
`确认路由`

> 你同意这条 Route。Codex 接下来会先做只读调查，不会马上修改文件。

`修改：...`

> 你要补充或修改这条 Route。Codex 会根据你的补充重新判断，然后再请你确认。

`继续聊聊`

> 你暂时不确认这条 Route，想继续讨论。Codex 会保留当前 Brief 和 Route 作为草稿，回到讨论，不会开始调查、Plan 或修改文件。

`取消`

> 你要停止当前任务。Codex 不会开始调查或修改文件。
```

For an explicit Bug-fix route, put the pre-write condition in the bold summary and show the full route handoff:

```markdown
**结论：先完成 full RCA，根因确认前不写文件。**

**路由：** Large
**模式：** implementation
**类型：** Bug 修复
**限制：** 根因确认前不写文件

**已完成：**
已经确认这是 Bug 修复请求，而且问题涉及多个调用方和多种失败情况，所以需要做 Large 级别的完整 RCA。

**下一步：**
先把代表性失败、共同调用机制和回归范围查清。根因确认之前，Codex 不会进入 native Plan 或修改文件。

**需要你确认：**
请先确认这条 Route。你确认后，Codex 才会开始只读的 full RCA，并在根因确认之前保持不写文件。

**怎么回复：**
`确认路由`

> 你同意这条 Route。Codex 接下来会开始只读的 full RCA，不会修改文件。

`修改：...`

> 你要修改当前 Route 判断。Codex 会按照你的补充重新判断，然后再请你确认。

`继续聊聊`

> 你暂时不确认这条 Route，想继续讨论。Codex 会保留当前 Brief 和 Route 作为草稿，回到讨论，不会开始 full RCA、Plan 或修改文件。

`取消`

> 你要停止当前 Bug 分析。Codex 不会进入 full RCA 或修改文件。
```

Stop after the card. Do not invoke `$option-explorer`, native Plan, Worktree, Goal, Review, or modify files while waiting. If the user chooses `继续聊聊`, return to discussion and keep the current Brief/Route as a draft. After `确认路由`, the Route must return a stage result plus a next-stage handoff; it may not end with a findings-only paragraph. Do not narrate a second workflow state machine; this is the one route handoff required at this boundary.

## Route

### Stage completion contract

Every routed stage must end with one visible handoff. The handoff names the current result, the next stage or terminal boundary, who acts next, the exact command or host action, and what remains forbidden. A read-only result is not a terminal state by itself: `check-only` and `plan-only` still show the user’s available next choice while preserving their no-write mode.

For a direct public `$task-router` entry, the Route card is the first stage handoff. After the user confirms it, the Workflow continues through investigation, RCA, Option evaluation, native Plan, implementation, verification, and completion according to the selected mode. No earlier Brief gate is inferred, but no later permission gate is skipped.

For a `check-only` result, use a result handoff instead of ending with findings alone:

```markdown
**结论：只读调查已完成，Codex 不会修改文件。**

**已完成：**
Codex 已经完成当前 Route 允许的检查，并列出证据、影响范围和仍然存在的不确定性。

**下一步：**
如果你要把结果转成修复任务，Codex 会整理 Brief；如果你只需要结论，Codex 会结束这次只读检查。

**需要你确认：**
请选择继续定义修复任务，还是保留只读结果。

**怎么回复：**
`整理 brief`

> 你要把只读结果转成修复任务。Codex 接下来会整理 Brief，但仍然不会修改文件。

`只保留结论`

> 你只需要这次检查的结论。Codex 会保留结果并结束当前只读检查，不会进入 implementation。

`继续聊聊`

> 你暂时不决定下一步，想继续讨论检查结果。Codex 会保留当前内容，不会进入修复或修改文件。

`取消`

> 你要停止当前任务。Codex 不会继续检查或修改文件。
```

For a `plan-only` result, report the Plan and state that the task ends at planning; do not ask for an execution confirmation or imply that a file write is available.

**Small** — Investigate only what is necessary. For a Bug in `implementation`, complete the focused RCA gate above before making the smallest change; for a non-Bug task, the minimal change may follow the route handoff. In `check-only` or `plan-only`, do not write. Run the project’s real targeted tests, lint, typecheck, build, or behavior checks; inspect the actual diff; then follow `AGENTS.md` for `git status` and the concise diff summary. Do not create an ExecPlan or Goal, and do not commit or publish automatically. Formal Review is normally unnecessary unless requested or the risk grows.

**Medium** — Investigate first. For a Bug, the read-only investigation must complete the focused/full RCA gate and establish the root cause before Plan or any write. For `implementation`, complete the necessary read-only investigation, then invoke the host’s actual native Plan and wait for it to complete successfully before modifying any file. A hand-written outline or `update_plan` is not proof that native Plan mode was used. If the current host cannot call native Plan itself, follow `Native Plan availability and handoff` below: output the filled Plan request immediately so the user can submit it after manually entering Plan mode, and stop before any write. For `check-only`, continue only with independent read-only checks that do not require Plan; after reporting the findings, show whether the user wants `整理 brief`, `只保留结论`, or another read-only action. For `plan-only`, return the plan with a clear terminal explanation and do not ask for execution. After a completed native Plan for `implementation`, use an explicit host action such as Implement or returning to execution mode as execution authorization. If the host has not supplied such authorization, display the plan outcome and stop for `确认计划，执行`; `修改计划` regenerates the handoff and `取消` stops. Run real verification for implementation. Use native Review or native Colleagues reviewer when there is meaningful logic, behavior, multi-module, concurrency, performance, or regression risk; do not force heavyweight Review for a low-risk Medium. Review never replaces tests; fix only confirmed findings and re-review when needed. If native Review is unavailable, provide the native handoff and do not self-review under another name.

For either Medium or Large, when native Plan is unavailable, use `Native Plan availability and handoff` below. Do not emit a bare `/plan`, and do not treat a prose outline or a user’s “我想好了” as native Plan completion.

**Large** — Complete full RCA before implementation planning is allowed to turn into a write: representative failures, shared mechanism, generalization boundary, and regression matrix must be explicit. Then use native Plan first. If the current host cannot call native Plan itself, follow `Native Plan availability and handoff` below: output the filled Plan request immediately and stop any implementation, ExecPlan persistence, Worktree, Goal, or Review until the native result is visible; a check-only task may continue only with independent read-only checks that do not need the plan, and its report must still include a next-stage or terminal handoff. After a completed native Plan for `implementation`, use an explicit host action such as Implement or returning to execution mode as execution authorization. If no such authorization is observable, display the Plan outcome and stop for `确认计划，执行`; include the proposed ExecPlan path, Worktree/Goal use, milestones, migration, and rollback choices in that card. `修改计划` regenerates it and `取消` stops. Only after execution authorization may the route persist a living ExecPlan using the repository’s convention (default: `docs/exec-plans/YYYY-MM-DD-<task>.md`) and use native Worktree or Goal when the current host actually exposes and permits them. Record goal/non-goals, current state, scope, constraints, risks, milestones and validation, compatibility/migration, rollback, progress, discoveries, decisions, acceptance criteria, and stop conditions; update progress as work changes. A Goal or Worktree must not be inferred or simulated: if the host requires an explicit user/UI action or no callable native entry exists, provide a precise handoff and stop. Never replace a Worktree with a copied directory or ordinary branch, or a Goal with an open-ended instruction. Verify every milestone, run final real checks, and use native Review against the actual base (normally `main`) before acceptance. In `check-only`, do not persist an ExecPlan or alter code; report the findings and show the next-stage or terminal handoff. In `plan-only`, show the plan and its terminal boundary without writing an ExecPlan, creating Worktree/Goal, implementing, or reviewing.

### 真实回复写作规则（适用于所有 Router/Plan 切换输出）

- 第一段是单句结论，使用加粗 `**结论：...**`，一句话交代当前状态与边界。
- 当同卡片里有两个以上并列要点时，用 `结论` + 明确分点的形式呈现；避免把复杂流程全塞到一行里。
- 每条动作语句保持一个主语（用户/Workflow/Codex）与一个动作，不叠加多个意图。
- 内部状态（如“内部已确认、内部未确认”）不写入用户可读路径，除非该状态直接影响授权。
- 口令行必须单独一段，不能用 `-`、`*`、`1.`，后面空一行，再用以 `> ` 开头的一段话说明用户选择之后会发生什么。
- Route、Option、native Plan 和其他尚未开始下一步的等待卡都要提供 `继续聊聊`；它只会回到讨论，不会触发调查、Plan、implementation 或文件修改。
- 每个正文段都要有明确主语，优先使用“你”、“Codex”、“代码”或“测试”；不要只写“已完成”、“进入下一阶段”这种没有主语的内部标签。
- 技术名词保留原文，但第一次出现时用一句短话说明它在这一步是干什么的；不把 Route、RCA、Plan 只当作内部状态名称。
- 轻量中文润色（humanizer-zh）：固定术语保留，普通的 `task`、`path`、`flow`、`handoff` 分别说成“任务”“处理逻辑/代码位置”“执行顺序”“下一步交接”。不要把英文标识符和抽象名词硬拼成“键盘事务替换路径”一类的中文；优先写“谁 + 做什么 + 结果”，只改表达，不改事实、权限、数值或结论。

## Native Plan availability and handoff

Use the current host’s actual capability names and semantics. A callable native Plan is the direct path. `update_plan` is a checklist/progress tool; it does not enter or exit native Plan mode and must not be used as its substitute.

When no callable native Plan is available, always show a handoff with a filled, copyable `Plan 请求` immediately. The request is the input needed for the user-run native Plan; requiring proof of a manual entry before providing that input creates a deadlock. Populate every field from the current brief and RCA; do not leave known values as placeholders. This handoff does not claim that Plan ran and does not authorize a write.

If the host’s exact entry syntax is unknown, tell the user to enter Plan mode through the host UI and paste the request into the current conversation; do not guess a slash command or additional parameters. Do not require an extra textual completion acknowledgement: the native Plan result appearing in the current conversation is the completion signal.

```markdown
**结论：请先在宿主中手动进入 Plan 模式，制定真实 native Plan。**

**Plan 请求：**

**任务目标：**
<目标>

**已确认的 RCA/证据：**
<根因与证据>

**范围：**
<范围>

**非目标：**
<非目标>

**约束：**
<约束>

**验收与验证：**
<验收标准>

请只制定 native Plan，不修改文件、不执行实现、不提交。

**下一步：**
请在宿主 UI 中手动打开 Plan，把上面的 `Plan 请求` 粘贴到当前对话。native Plan 结果出现前，Codex 不会写文件。
```

The block above defines the field order only. In a live handoff, replace every angle-bracketed item with the actual brief and RCA facts before showing it to the user. The live handoff must explicitly say to enter Plan through the host UI and paste the filled request into the current conversation. Once the real native result is visible, consume it directly; do not request another message merely to acknowledge completion and do not ask the user to paste or upload the same result again.

For `implementation`, proceed when the user has used the host’s explicit Implement action or the host has otherwise returned the task to execution mode with the Plan visible. If only the Plan result is visible and execution authorization is not observable, use the completion handoff below. For `check-only` or `plan-only`, show the result and stop without entering execution.

## Option checkpoint

After the confirmed route’s necessary read-only investigation, explicitly evaluate the three `$option-explorer` conditions. Do not enter it immediately after the route merely because the task is Large. If the conditions are met, stop before native exploration and show:

```markdown
**结论：当前存在需要额外探索的高成本技术分叉。**

**选项检查：**
发现两个（或更多）实质不同、成本都高且暂无明显赢家的方案。

**下一步：**
Codex 可以进入 Option，比较这些方案的实现成本、风险和回滚方式；这会增加探索时间和 Token 消耗。

**请确认：**
你要不要让 Codex 先做这次额外比较？

`进入 option`

> 你同意进入 Option。Codex 接下来会比较候选方案，不会直接修改文件。

`跳过 option`

> 你不需要额外比较。Codex 接下来会直接进入下一阶段，不会因为跳过 Option 而修改文件。

`继续聊聊`

> 你暂时不选择 Option，想继续讨论。Codex 会保留当前判断，回到讨论，不会开始方案比较或修改文件。
```

`进入 option` is the only permission to invoke the optional Skill. `跳过 option` means continue directly to the required native Plan or confirmed Small route. `继续聊聊` leaves the Option checkpoint without invoking it and returns to discussion. If the conditions are not met, state `Option 不触发` and flow directly into the already-required next stage: invoke callable native Plan, output the filled manual Plan request, or continue the confirmed Small route. Do not insert another text confirmation for a branch that did not trigger.

When Option does not trigger, make the next handoff explicit instead of silently continuing:

```markdown
**结论：Option 不触发，当前修复路径明确。**

**选项检查：**
当前证据不足以证明存在高成本且无明显赢家的分叉。

**下一步：**
Codex 接下来会进入 <下一阶段>。如果这个阶段需要你手动操作或确认，Codex 会在这里把具体动作写清楚。

Option 未触发时，在同一条回复中继续输出下一阶段的真实内容；如果下一阶段是手动 Plan，紧接着输出填满的 `Plan 请求`。
```

After `选择 A` or `选择 B` (the shortest aliases `A` or `B` are acceptable), flow directly into the required planning stage: invoke callable native Plan, or immediately output the filled manual Plan request. `回到 Plan` expresses the same choice. `继续聊聊` leaves the selection handoff without entering Plan and returns to discussion. Do not add another text confirmation between option selection and the Plan input; the no-write boundary remains until the real native result and execution authorization are observable.

## Native Plan completion handoff

When a required native Plan completes and its result is observable, show the result before any write:

```markdown
**结论：native Plan 结果已可见，等待你确认后进入 implementation。**

**已完成：**
Plan 已经列出要改的范围、主要风险和验证方法。native Plan 是宿主提供的实施计划，不是普通文字大纲。

**下一步：**
如果你确认执行，Codex 会进入 implementation，按这份 Plan 修改文件并运行验证。

**需要你确认：**
请确认是否接受这份 Plan。当前卡片中的 ExecPlan、Worktree、Goal、迁移和回滚安排，也会按 Plan 中列出的内容执行。

**怎么回复：**
`确认计划，执行`

> 你接受这份 Plan，并授权 Codex 开始 implementation。Codex 接下来会修改文件并运行验证。

`执行`

> 你用简写确认执行。Codex 会把它当作“确认计划，执行”，然后开始 implementation。

`修改计划`

> 你不同意当前 Plan。Codex 会先停在这里，按照你的要求重新整理计划，不会修改文件。

`继续聊聊`

> 你暂时不执行这份 Plan，想继续讨论。Codex 会保留 Plan 结果，回到讨论，不会修改文件。

`取消`

> 你要停止当前任务。Codex 不会执行这份 Plan，也不会修改文件。
```

For `check-only` or `plan-only`, show the Plan/findings and stop without asking for execution. A user-run fallback is complete only when the actual native result is visible, not when the user sends a separate acknowledgement.

## Truthfulness and finish

Use the current host’s capability names and semantics, not stale assumptions. Never claim that Plan, Review, Colleagues, a sub-agent, Worktree, or Goal ran unless its invocation succeeded and its result is observable. Do not simulate any of them with custom prompts, a second Git workflow, hashes, baselines, frozen contracts, hard gates, or a private verification framework. Never write a Bug fix before the RCA gate is complete. Commit and publish only when the user explicitly requests the repository’s `AGENTS.md` command. After the routed task reaches its completion boundary, return control to the Workflow’s completion handoff; do not start `$repo-retrospective` without the user’s `进入复盘` confirmation. A later ordinary conversation starts in discussion mode.

For boundary examples and manual acceptance checks, read [references/routing-cases.md](references/routing-cases.md) only when validating this router or resolving an ambiguous gate.
