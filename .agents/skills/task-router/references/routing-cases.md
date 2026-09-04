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
| “$engineering-workflow 修复 Markdown 第一次打开明显卡顿的问题，完成后运行相关检查。” | Display and confirm the brief, show and confirm Medium routing, investigate, explicitly report whether Option triggers, then complete native Plan before any write. An explicit host Implement/return-to-execution action authorizes implementation; only ask `确认计划，执行` when the host has not provided that authorization. |
| “$engineering-workflow 修复一个 Medium Workflow 规则 Bug；宿主没有 callable native Plan，也没有预先声明手动 Plan 入口。” | After RCA and routing, immediately show a filled `Plan 请求` containing the current goal, RCA/evidence, scope, non-goals, constraints, and acceptance/validation. Tell the user to enter Plan through the host UI and paste it into the current conversation; do not require prior entry confirmation or an extra textual completion acknowledgement. |
| “brief 已确认，路由调查完成；下一步需要 Plan。” | Output the filled Plan request immediately; do not ask the user to prove that a manual entry exists, return to the conversation, or acknowledge a result that will already be visible here. |
| “Plan 结果已经显示在当前会话。” | Consume the visible native result directly and do not request a second copy or completion receipt. For `implementation`, proceed when the host’s Implement/return-to-execution action is observable; otherwise ask `确认计划，执行`. |
| “检查 parser 模块的测试为什么失败，不要改代码。”（未显式调用 Workflow） | Ordinary host handling; do not implicitly activate the engineering workflow. |
| “$engineering-workflow 检查 parser 模块的测试为什么失败，不要改代码。” | Display and confirm the brief, show and confirm Small/Medium `check-only` routing, perform only read-only checks, and do not enter implementation or retrospective without a new explicit request. |
| “$engineering-workflow 把配置存储从 JSON 迁移到 SQLite，要求兼容旧数据并提供回滚。” | Display and confirm the brief, show and confirm Large routing, investigate, ask whether to enter Option if its three conditions hold, and complete native Plan. If the host’s Implement/return-to-execution action is observable, continue with the named ExecPlan/Worktree/Goal/rollback choices; otherwise ask `确认计划，执行` once. After checks and Review, ask `进入复盘` or `跳过复盘`. |
| “$engineering-workflow 修复一个 Large Workflow 规则 Bug；宿主没有 callable native Plan，也没有预先声明手动 Plan 入口。” | Immediately issue the filled Plan request for the user to submit through the host UI. Do not create a prose substitute, persist an ExecPlan, or write files before the native result and execution authorization are observable. |
| “$task-router 为 Workflow 规则修复制定计划，只做计划；当前只有 `update_plan`。” | Do not treat `update_plan` as native Plan. Immediately show the filled user-run Plan request, tell the user to enter Plan through the host UI, and stop after the real Plan result because the route is `plan-only`. |
| “$task-router 评估多窗口架构迁移，只做计划，不修改文件。” | Show Large / `plan-only` route and wait for `确认路由`; no file writes, ExecPlan persistence, Worktree, Goal, implementation, or automatic retrospective. |
| “$engineering-workflow 把刚才讨论的设置改动落到仓库，并运行相关测试。” | Always display and confirm the five-item Task Brief, show and confirm the route, explicitly announce whether Option triggers, and use the required native stages only after their handoff confirmations. |
| “$task-brief 把刚才讨论的架构想法整理成任务定义，不要实施。” | Display the five-item Brief; after `确认`, continue to the Route stage while preserving the no-write boundary until the required Plan and execution authorization. If the user explicitly says “只整理 brief”，stop after the Brief. |
| “$rca-analyze 这个 Skill 为什么调不起来？先分析，不要修。” | Enter the Workflow at RCA, keep the review read-only, and after the RCA report offer `整理 brief` as the repair handoff or `只保留结论` as the terminal branch. |
| “$task-router 评估这个 Workflow 规则问题并修复。” | Enter the Workflow at Route, show and confirm the Route handoff, then continue through investigation, Option evaluation, native Plan, implementation, verification, and completion without asking the user to rediscover the next stage. |
| “$option-explorer 比较这两条已经确认的技术路线。” | Enter the Workflow at Option, check the three trigger conditions, and after a selected direction flow directly into native Plan or the filled manual Plan request. |
| “$repo-retrospective 检查刚才的任务有没有可重复的仓库摩擦。” | Run the optional terminal retrospective and show its write/record/cancel choices; do not start another engineering stage automatically. |
| “完成这个工程任务后，检查是否有可重复的仓库环境摩擦。” | Use `$repo-retrospective`; default to no changes and persist only evidence-backed recurring improvements. |

## Native Plan end-to-end acceptance transcripts

### Scenario 1 — Medium implementation without a callable Plan entry

**Setup:** A Medium Bug repair has a confirmed brief, route, RCA, and `Option 不触发`. The host exposes no callable Plan tool and the user has not pre-confirmed a manual entry.

**Step 1 — Workflow reply:**

> **结论：下一步需要 native Plan，请把下面的完整请求提交到宿主 Plan 模式。**
>
> **Plan 请求：**
>
> **任务目标：**
> 修复 TencentVoiceMVP 停止时删除已提交文本的竞态，保留 ASR 句内修正。
>
> **已确认的 RCA/证据：**
> `final` 与 `finished` 均保留 31 个字符，删除发生在下游注入层；风险集中于 `SessionCoordinator.swift` 停止竞态和 `AXTextTarget.swift` 异步退格。
>
> **范围：**
> 统一已提交前缀/当前可变片段状态，增加停止屏障，串行化输入事件，补充回归测试。
>
> **非目标：**
> 不更换现有 macOS MVP 架构，不改 ASR 供应商，不提交或发布。
>
> **约束：**
> Plan 阶段只读；必须严格区分已提交前缀与可变片段；保留用户无关改动。
>
> **验收与验证：**
> 覆盖句内修正、停止与 final 并发、异步退格三类回归；运行现有 39 个测试及新增定向测试。
>
> 请只制定 native Plan，不修改文件、不执行实现、不提交。
>
> **下一步：**
> 请通过宿主 UI 手动进入 Plan 模式，并将以上请求作为下一条消息提交。

**Step 2 — User action:** Manually enter the host’s Plan mode and submit the filled request in the current conversation.

**Step 3 — Native Plan reply:** Return a read-only implementation plan covering the three regression seams, unified segment state, the stop barrier, serialized AX events, and final verification. The result remains visible in this conversation. No extra textual completion acknowledgement is requested.

**Step 4 — Execution boundary:** If the user chooses the host’s Implement action and the task returns to execution mode, begin implementation from the visible Plan. If the host exposes no such action, ask `确认计划，执行` once.

### Scenario 2 — Large implementation after Option selection

**Setup:** A Large JSON-to-SQLite migration has completed full RCA. Option exploration found two viable approaches: A uses an online compatibility layer and staged backfill; B uses a maintenance-window migration with rollback snapshots.

**Step 1 — Option reply:**

> **结论：推荐 A，它保留旧数据兼容和可回滚性，代价是过渡期双路径复杂度。**
>
> **候选方案：**
> A：在线兼容层 + 分批回填 + 可回退到 JSON。
> B：维护窗一次性迁移 + 快照回滚。
>
> **请回复：**
`选择 A`

> 你选择在线兼容路径。Codex 接下来会按这个方向提交 Plan，不会直接修改文件。

`选择 B`

> 你选择维护窗路径。Codex 接下来会按这个方向提交 Plan，不会直接修改文件。

`取消`

> 你要停止 Option。Codex 不会选择方案，也不会进入 Plan 或修改文件。

**Step 2 — User selection:** `选择 A`

**Step 3 — Workflow reply:**

> **结论：已选择在线兼容路径，请把下面的完整请求提交到宿主 Plan 模式。**
>
> **Plan 请求：**
>
> **任务目标：**
> 将配置存储从 JSON 迁移到 SQLite，保持旧数据兼容并可回滚。
>
> **已确认的 RCA/证据：**
> 现有 JSON 写入在并发和部分失败时缺少事务边界；代表性数据与回滚要求已确认。
>
> **范围：**
> 在线兼容层、分批回填、读写切换、一键回退到 JSON、数据一致性验证。
>
> **非目标：**
> 不重写上层配置 API，不在 Plan 阶段创建 ExecPlan 或 Worktree。
>
> **约束：**
> 保留现有公开行为；迁移可中断、可恢复；数据不丢失；根因未变更。
>
> **验收与验证：**
> 覆盖旧数据升级、重复启动、中断恢复、双写一致性、切换与回滚；说明里程碑和停止条件。
>
> 请只制定 native Plan，不修改文件、不执行实现、不提交。
>
> **下一步：**
> 请通过宿主 UI 手动进入 Plan 模式，并将以上请求作为下一条消息提交。

The selected direction flows directly into callable Plan or the filled manual Plan request. No additional Plan-entry confirmation appears between Step 2 and Step 3.

### Scenario 3 — Host returns from native Plan to execution

**Setup:** Scenario 1’s filled request has been submitted in native Plan mode. The Plan result is visible in the current conversation and the host presents its normal Implement action.

**Step 1 — Native Plan reply:**

> **计划结论：先用三个并发回归锁定下游注入边界，再统一分段状态、增加停止屏障并串行化 AX 事件。**
>
> 1. 为句内修正、stop/final 竞态、异步退格各写一个会在旧实现上失败的回归。
> 2. 用单一分段状态表达已提交前缀与当前可变片段。
> 3. 让 stop 等待最后一次 final 和已排队的注入事件完成。
> 4. 串行化 AX 删除/插入事件，并在会话结束后忽略过期操作。
> 5. 运行新增定向测试、现有 39 个测试、diff 和 git status 检查。

**Step 2 — User host action:** Choose the host’s Implement action. The host returns the same task to execution mode with the Plan result still visible.

**Step 3 — Workflow execution reply:**

> **已读取当前会话的 native Plan，宿主已通过 Implement 操作切回执行模式。**
>
> 我现在按计划先补三个并发回归，确认它们在旧实现上失败，再开始修改生产代码。

No completion receipt or duplicate execution confirmation is requested. Implementation begins only because both the real Plan result and the host’s execution authorization are observable.

## Public Skill stage-continuation acceptance transcripts

These cases verify that a direct public Skill invocation starts the full Workflow at that stage. The continuation is visible, but each later permission gate remains in force.

### Scenario 4 — Direct RCA entry returns to Brief

**Setup:** The user invokes `$rca-analyze` for a symptom-only Bug and does not authorize a fix.

**Expected:** Codex performs read-only RCA, reports the confirmed or unconfirmed root cause, and shows `整理 brief`, `只保留结论`, `继续调查`, `继续聊聊`, and `取消`. Choosing `整理 brief` produces the five-item Brief; choosing `只保留结论` ends the read-only path. No file is modified.

### Scenario 5 — Direct Router entry continues after Route

**Setup:** The user invokes `$task-router` with an implementation request.

**Expected:** Codex shows and confirms the Route card without inventing an earlier Brief gate. After `确认路由`, Codex performs the required investigation, reports the Option decision, and continues to native Plan or the filled manual Plan request. The Route result never ends with findings alone.

### Scenario 6 — Direct Option entry returns to Plan

**Setup:** The user invokes `$option-explorer` and the three Option trigger conditions hold.

**Expected:** Codex compares the candidate paths, waits for `选择 A` / `选择 B` / `回到 Plan` / `继续聊聊` / `取消`, and sends a selected direction directly to native Plan or the filled manual Plan request. No second Plan-entry confirmation appears.

### Scenario 7 — Direct Brief entry returns to Route

**Setup:** The user invokes `$task-brief` for an action-ready repository task.

**Expected:** Codex displays the five-item Brief. After `确认`, Codex shows the Route handoff; `先聊一聊` keeps the Brief as a draft and `取消` stops. A standalone Brief is terminal only when the user explicitly asks to keep the Brief without routing.

### Scenario 8 — Check-only result has a visible next choice

**Setup:** A confirmed Route runs a `check-only` investigation and reaches a stable result.

**Expected:** Codex reports the result and then shows the next read-only action or `整理 brief` / `只保留结论` terminal choice. The response does not ask for implementation authorization and does not stop after a findings-only paragraph.

## 场景化中文验收稿（10 套真实输出样例）

以下示例均采用同一风格：复杂信息用一个自然段；并列信息使用结论+要点；每个口令单独成段，与说明之间空一行，说明段以 `> ` 开头；无列表标记。

### 场景一：生成 Brief

**改前（问题）**

> 目标：修复结束后全删。当前上下文/证据：final 和 finished 正常，归一化没有清空。约束与授权：保留现有 macOS MVP 架构。范围/非目标：统一分段状态、增加停止屏障、串行化输入事件。

**改后（期望）**

**目标：停止录音后，输入框里已经出现的文字不能再被删掉。**

**目前确认的情况**
- 腾讯 ASR 最后返回的 `final` 和 `finished` 都包含完整文字。
- 文字是在送进目标输入框以后才被删除的。
- 问题集中在停止录音和模拟退格这两段流程。

**本次限制**
- 保留现有 macOS MVP 架构。
- 现在只确认任务范围，还不修改文件。

**这次会处理**
- 查清停止录音时，各个异步事件的执行顺序。
- 让文字更新和退格事件按正确顺序执行。
- 补充能够复现误删问题的测试。

**怎样算完成**
停止录音后，最终文字保持不变；句内修正仍然正常；相关测试全部通过。

**请确认这份任务摘要**

`确认`

> 你同意这份任务摘要。Codex 接下来会判断这个任务应该进入哪条工作流程，但不会因此直接修改文件。

`修改：请把……改成……`

> 你不同意当前的任务摘要。Codex 会按照你写的要求重新整理完整摘要，然后再次请你确认。

`先聊一聊`

> 你暂时不确认这份任务摘要，想先继续讨论。Codex 会保留当前摘要作为未确认草案；讨论期间不会进入任务路由、Plan 或实施。等你明确说“整理任务摘要”后，Codex 才会重新整理摘要并再次请你确认。

`取消`

> 你要停止当前任务。Codex 不会继续路由、规划或实施。

### 场景二：用户选择“先聊一聊”

**改前（问题）**

> Brief 已冻结为暂存草案，当前进入 Exploration mode，不进入 Router、Plan 或修改文件。

**改后（期望）**

> 好的，我先保留这份 Brief，不进入 Route、Plan 或修改文件。你可以继续补充想法；等你说“整理 Brief”时，我再把讨论内容整理成一份新的 Brief。

### 场景三：Route 判断

**改前（问题）**

> 结论：先做必要的只读调查；调查后再检查是否触发 Option。路由：Medium；模式：implementation；类型：普通工程任务。已确认后按 `确认路由` 继续。

**改后（期望）**

**结论：先查清停止录音和退格事件的执行顺序，再制定 Plan。**

这个问题涉及三个互相影响的部分：
- 停止录音时怎样结束 ASR 会话。
- 最后一段文字怎样写入输入框。
- 已经排队的退格事件会不会继续执行。

直接修改其中一处可能制造新的误删问题，所以这项任务按 Medium 处理。

你确认 Route 后，Codex 会先做只读调查，不会马上修改文件。

`确认路由`

> 你同意这条 Route。Codex 接下来会先做只读调查，不会马上修改文件。

`修改：...`

> 你要补充或修改这条 Route。Codex 会根据你的补充重新判断，然后再请你确认。

`继续聊聊`

> 你暂时不确认这条 Route，想继续讨论。Codex 会保留当前内容，回到讨论，不会开始调查、Plan 或修改文件。

`取消`

> 你要停止当前任务。Codex 不会开始调查或修改文件。

### 场景四：RCA 未确认根因

**改前（问题）**

> 根因：尚未确认。影响范围待定。需要继续补充证据与调用链，当前不进入 Option、native Plan 或 implementation。

**改后（期望）**

**结论：现在只能确认文字是在输入阶段被删掉，还不能确定是哪一个事件造成的，所以不会修改代码。**

已确认：
- ASR 返回的最终文字是完整的。
- 文本归一化没有把内容清空。
- 删除发生在辅助功能事件发送以后。

还需要确认：
- 停止录音时是否仍有退格事件排在队列里。
- 状态清理和退格事件哪一个先执行。

下一步，Codex 会读取这两条调用链，并找出能够稳定复现问题的事件顺序。

### 场景五：RCA 已确认根因

**改前（问题）**

> RCA 已完成；根因、证据和影响范围已记录。主要风险集中在停止竞态以及异步退格事件。

**改后（期望）**

**结论：根因已经确认。停止流程清理文字状态时，之前排队的退格事件仍可能继续执行，因此最终文字会被删掉。**

证据包括：
- ASR 已经返回完整的最终文字。
- 状态清理完成后，日志里仍然出现退格事件。
- 禁用这批延迟退格后，文字不再消失。

这会影响“停止后全删”外，还可能影响“句内修改刚提交内容”场景，删除误差会同样发生。

修复要同时做两件事：
- 停止流程必须等待已排队的输入事件结束。
- 文字写入和退格事件必须按同一顺序执行。

### 场景六：Option 不触发

**改前（问题）**

> Option 不触发。当前 brief 已明确保留现有架构，修复方向是统一分段状态、增加停止屏障、串行化输入事件。

**改后（期望）**

**结论：这次不需要比较多套方案。**

日志已经把问题缩到两个点：
- 停止录音时，状态可能在错误时间被清理。
- 退格事件可能延迟到达，误删已确认文字。

修复方向已经明确，没有两条成本接近、但取舍完全不同的路线。下一步直接围绕这两个问题制定 Plan，因此这次不进入 Option。

### 场景七：Option 需要触发

**改前（问题）**

> 当前存在需要额外探索的高成本技术分叉。选项：配置从 JSON 迁移到 SQLite，有两条差异路线，但没有明确赢家。

**改后（期望）**

**结论：把配置从 JSON 迁移到 SQLite 有两条差别很大的路线，但目前都没有明显赢家。**

- 在线迁移不需要停机，但要同时维护 JSON 与 SQLite 两套读写逻辑，代码更复杂。
- 停机迁移实现简单，也更容易回滚，但用户在迁移期间无法使用应用。

两个方案都会影响数据安全和发布方式。当前选 `进入 option` 做完整比较，选定后再进入 native Plan，因此这类分叉仍需走 Option。

`进入 option`

> 你同意进入 Option。Codex 接下来会比较候选方案，不会直接修改文件。

`跳过 option`

> 你不需要额外比较。Codex 接下来会直接进入 Plan，不会因为跳过 Option 而修改文件。

`继续聊聊`

> 你暂时不进入 Option，想继续讨论。Codex 会保留当前判断，回到讨论，不会开始方案比较或修改文件。

### 场景八：需要手动打开 Plan

**改前（问题）**

> 当前宿主未向我暴露可调用或可验证的 native Plan，不能用普通文字大纲替代 Plan，也不能直接进入写入阶段。

**改后（期望）**

**结论：请先在宿主中手动打开 Plan；我已经把可以直接粘贴的 Plan prompt 写好。**

请在宿主 UI 中打开 Plan，把下面的内容粘贴到当前对话。native Plan 结果出现前，Codex 不会修改文件。

```text
请为“停止录音后文字被误删”制定实施 Plan。

已经确认：
- ASR 返回的最终文字完整。
- 停止流程和延迟退格会交错执行。
- 修复需要统一输入事件顺序，并让停止流程等待队列结束。

Plan 需要说明：
- 修改哪些状态和调用顺序。
- 怎样保留句内修正能力。
- 先补哪些回归测试。
- 怎样验证停止录音、连续修正和快速启停。

只制定 Plan，不修改文件，不执行实现，不提交。
```

### 场景九：Plan 已完成但尚未授权执行

**改前（问题）**

> native Plan 结果已可见，但是否进入 implementation 还需要继续确认。

**改后（期望）**

**结论：Plan 已经完成，但 Codex 还没有修改文件。**

这份 Plan 已确定：
- 先补三个能够复现误删问题的测试。
- 再统一文字写入和退格事件的执行顺序。
- 最后验证停止录音、句内修正和快速启停。

当前任务不需要 Worktree、Goal、数据迁移或回滚方案。

`确认计划，执行`

> 你接受这份 Plan，并授权 Codex 开始 implementation。Codex 接下来会修改文件并运行验证。

`修改计划`

> 你不同意当前 Plan。Codex 会先停在这里，按照你的要求重新整理计划，不会修改文件。

`继续聊聊`

> 你暂时不执行这份 Plan，想继续讨论。Codex 会保留 Plan 结果，回到讨论，不会修改文件。

`取消`

> 你要停止当前任务。Codex 不会执行这份 Plan，也不会修改文件。

### 场景十：完成报告（含验收）

**改前（问题）**

> 实现和验证已完成，可选择是否进入复盘。已完成实现、真实验证、Review，以及 git status/diff 摘要。

**改后（期望）**

**结论：修复已经完成。停止录音后，输入框里的最终文字不会再被延迟退格删掉。**

这次修改了两个地方：
- 统一文字写入和退格事件在同一执行顺序。
- 停止录音会等待已排队的输入事件结束，再清理会话状态。

验证结果：
- “停止后全删”回归测试通过。
- 句内修正、连续录音和快速启停测试通过。
- 目前显示的 39 个测试全部通过。
- Review 没有发现新的阻塞问题。

当前工作区仅有本次相关修改，没有提交或发布。

`进入复盘`

> 你要检查这次任务是否暴露了可重复的仓库问题。Codex 会进入复盘，但不会默认修改文件。

`跳过复盘`

> 你不需要复盘。Codex 会保留完成报告并结束当前任务。

`继续聊聊`

> 你想继续讨论完成结果。Codex 会保留完成报告，不会进入复盘或执行其他操作。

`取消`

> 你要停止当前 Workflow。Codex 不会进入复盘或继续其他操作。

## 中文可读性回归验收（10 套具体场景）

这些场景专门检查“技术内容准确，但中文不拗口”。机器校验只检查结构；验收人要朗读“改后”内容，确认半技术用户不需要猜主语、动作或因果。润色只改表达，不改事实、权限、数值或结论。

### 场景 1：RCA 解释文本替换机制

**触发条件：** RCA 已确认 `PastedTextDelta` 只计算公共前缀，长文本修订会整段删除后重发。

**改前：** “问题集中在键盘事务替换路径，PastedTextDelta 导致长文本修订时整体退格并重发。”

**改后：** “RCA 找到的问题在键盘输入的文本替换逻辑里。`PastedTextDelta` 只比较新旧文本开头相同的部分，所以长文本修改时，代码会先删掉整段内容，再重新输入新内容。”

**验收标准：** 保留标识符和因果关系；不出现“事务替换路径”这类未解释的复合词；读者能说出是谁做了什么。

### 场景 2：Route 说明下一步

**触发条件：** 用户已经确认 Brief，Route 判断需要先做只读调查。

**改前：** “确认后进入下一阶段，继续判断流程。”

**改后：** “你确认这条 Route 后，Codex 会先读取调用链和测试结果，判断问题是否需要进入 Option；在判断完成前，Codex 不会修改文件。”

**验收标准：** 明确写出用户、Codex 各自的动作，以及调查期间不会写文件。

### 场景 3：Brief 解释技术约束

**触发条件：** 任务要求保留现有 API，只修复并发下的文本丢失。

**改前：** “Task scope 聚焦于 concurrency compatibility，避免影响既有行为。”

**改后：** “这次只处理并发情况下的文本丢失。现有 API 保持不变，其他输入行为也不调整。”

**验收标准：** 普通正文使用“任务”而不是孤立的 `Task`；技术约束和非目标都能直接读懂。

### 场景 4：RCA 的 `整理 brief` 口令

**触发条件：** RCA 已确认根因，用户需要把结果转成修复任务。

**改前：** “下一步请回复 `整理 brief`，我会继续处理。”

**改后：**

`整理 brief`

> 你要把已确认的 RCA 结果整理成修复任务。Codex 接下来会生成 Brief，再按 Route 和 Plan 继续；现在不会修改文件。

**验收标准：** 口令独占一段，说明单独成段并以 `> ` 开头；复制时只得到 `整理 brief`。

### 场景 5：check-only 调查结束

**触发条件：** 只读调查已完成，但用户没有要求修复。

**改前：** “调查完成，报告结果后停止。”

**改后：** “Codex 已经完成只读调查。你可以把结果整理成修复 Brief，也可以只保留这次结论；在你选择之前，Codex 不会修改文件。”

**验收标准：** 不使用“报告后停止”这种内部状态句；用户能看出下一步选项和权限边界。

### 场景 6：Option 比较两条路线

**触发条件：** 两种实现方式成本接近，且都可能影响数据回滚。

**改前：** “Option A/B 存在架构差异，需进行方案决策。”

**改后：** “方案 A 迁移更平滑，但过渡期要同时维护两套读写逻辑。方案 B 实现更简单，但迁移时应用需要暂停。你选定方向后，Codex 会把它交给 native Plan。”

**验收标准：** 说明每个方案具体差在哪里、代价是什么，以及选择后由谁做什么。

### 场景 7：手动 native Plan 提示

**触发条件：** 当前宿主没有可调用的 native Plan。

**改前：** “需要替换 Plan 路径，请进入下一流程。”

**改后：** “当前宿主没有可调用的 native Plan。Codex 已经准备好 Plan 请求；你打开 Plan 模式并粘贴下面的内容，Plan 结果出现前不会写文件。”

**验收标准：** 使用“手动打开 Plan 并粘贴请求”这种具体动作，不出现“替换路径”“切换流程”等没有对象的说法。

### 场景 8：直接调用 `$rca-analyze`

**触发条件：** 用户直接调用 RCA Skill，只要求查清原因。

**改前：** “RCA 输出完成，Task 将进入后续链路。”

**改后：** “RCA 已经查清现象、证据和调用顺序。你回复 `整理 brief` 后，Codex 会把这些内容整理成 Brief；如果你只想看结论，可以回复 `只保留结论`。”

**验收标准：** 保留 `RCA` 这个阶段名称，但用“任务”说明普通语义；下一步和终点都能直接执行。

### 场景 9：复盘结果

**触发条件：** 完成报告发现测试命令在本地和 CI 中不一致。

**改前：** “发现环境治理路径存在偏差，建议推进闭环。”

**改后：** “本地和 CI 使用了不同的测试命令，导致同一改动得到不同结果。Codex 建议把共同命令写进脚本；你确认后才会修改文件。”

**验收标准：** 把抽象名词换成具体对象、证据和动作；用户知道改哪个地方、为什么改。

### 场景 10：完成报告

**触发条件：** 实现和回归测试都已完成，准备交付结果。

**改前：** “实现、验证和 Review 已完成，工作流进入闭环。”

**改后：** “修复已经完成。测试确认停止录音后文字不会再被延迟退格删掉，Review 也没有发现新的阻塞问题。当前工作区只包含本次修改，Codex 没有提交或发布。”

**验收标准：** 先说用户最关心的结果，再说明测试、Review、工作区和提交状态；不使用“进入闭环”这类空话。

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
- Every reply command is a standalone command line, followed by one blank line and a separate explanation paragraph beginning with `> `. Do not use list/numbered markers or semicolons to join actions.
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
- Normal user-facing callouts use a public allowlist: `$engineering-workflow`, `$task-brief`, `$task-router`, `$rca-analyze`, `$option-explorer`, and `$repo-retrospective`. Other local Skills are described as capabilities such as `结构化探索` or `逐项澄清`; no unsupported `hidden` metadata field is invented, and host-rendered Skill chips are not misrepresented as hidden.
- `$rca-analyze` is the read-only Bug-review stage. Its result must show the next handoff (`整理 brief`, `只保留结论`, or another read-only action) and must not silently enter implementation.
- Do not silently chain internal discussion helpers. Public orchestration Skills are connected Workflow stages: after one returns, apply its stage handoff and continue when the user selects the provided command.
- A direct/urgent phrase in the initial Workflow message cannot serve as pre-confirmation. After the Brief is displayed, “确认”“按这个做” or “直接修” may confirm it, while preserving all route stages.
- The brief’s fifth item ends with a concrete reply contract: `确认` continues to Router, `修改：...` regenerates the full brief, `先聊一聊` freezes the snapshot and enters Exploration, and `取消` stops.
- A correction regenerates the complete five-item Brief and waits again; an explicit cancellation ends the active Workflow without routing or writing.
- After an explicit `$engineering-workflow` invocation, “直接修”“马上做”“不要再问” or “跳过计划” cannot implicitly bypass a required stage; only an explicit exit or cancellation of the Workflow can end it early.
- Every Router result includes a route handoff and waits for `确认路由`; it does not silently enter Option, Plan, or implementation.
- After read-only investigation, the agent explicitly reports whether the three Option conditions hold. If they hold, `进入 option` is required; `跳过 option` continues to the next-stage handoff.
- Option exploration ends with a selection handoff (`选择 A/B`, `回到 Plan`, or `取消`) and never authorizes writes by itself.
- A Small implementation may proceed directly only after route confirmation. A Medium implementation must complete native Plan after read-only investigation and before any write; a Large implementation follows the existing native Plan and milestone requirements. After native Plan, an explicit host Implement/return-to-execution action authorizes implementation; ask `确认计划，执行` only when that host authorization is not observable. Worktree, Goal, ExecPlan, migration, and rollback choices remain visible. Routine work after authorization need not pause, but consequential product, architecture, API, compatibility, data-loss, security, irreversible/costly choice, or explicit wait still pauses.
- A Small Bug implementation still requires focused RCA before the first write. A systemic/Large Bug requires representative failures, the shared mechanism, a generalization boundary, and adjacent regression checks before native Plan or implementation.
- A native-looking outline, a custom diff review, an ordinary branch, or an open-ended “keep going” prompt is not respectively native Plan, native Review, Worktree, or Goal.
- Review is additional evidence; it never substitutes for real tests.
- `$engineering-workflow` is the top-level entry point, and the other five public Skills are valid stage entries into the same Workflow.
- An explicit `$task-router` invocation enters at Route, skips only the earlier Brief gate, and still receives the route handoff plus all later investigation, Option, Plan, implementation, verification, and completion boundaries.
- An explicit `$task-brief`, `$rca-analyze`, or `$option-explorer` invocation likewise enters at that stage and must return the next-stage handoff; only an explicit terminal mode stops at the current stage.
- `$option-explorer` is opt-in and only applies when multiple materially different paths have no clear winner and a wrong choice is costly; internal entry requires `进入 option` and result selection.
- Medium/Large completion always shows a final result handoff and asks `进入复盘` or `跳过复盘`; `$repo-retrospective` is never started automatically. Its own candidate changes require `确认写入`.
- The completion card is a task-result summary, not the retrospective itself; choosing `跳过复盘` still returns the final summary and stops.
- `定稿` and `发布` remain repository `AGENTS.md` commands, not Small/Medium/Large classifications.
