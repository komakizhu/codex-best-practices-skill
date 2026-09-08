---
name: option-explorer
description: "Use when a repository task has two or more materially different viable technical paths, no obvious winner, and a costly wrong choice, after the user opts into extra exploration."
---

# Option Explorer

This is an optional decision aid, not a replacement for native Plan, Review, or implementation. It is a user-confirmed branch in the main Workflow, not an automatic step. Consider it only when all three trigger conditions hold:

- at least two materially different viable technical approaches exist;
- current evidence does not establish a clear winner; and
- choosing poorly would create meaningful rework, compatibility, performance, data, or architectural cost.

Do not invoke it merely because a task is Large, unfamiliar, or interesting. Before spending extra tokens, ask the user whether they want native Colleagues, Best-of-N, or parallel exploration. If they decline, continue with the normal native Plan route.

## 每条可见回复都要有下一步

Option 的每条可见回复都必须先说当前结论，再说明 Codex 已完成的比较、下一步由谁执行和当前不会做什么。方案比较结束后必须说明各方案优劣、证据和不确定性，给出推荐及理由，再询问 `采用 A`、`采用 B`、`继续聊聊` 或 `取消`，并用 `> ` 说明选择后的结果。需要其他方向时，用户通过 `继续聊聊` 补充；Option 不展示重复的保留、返回或替代方向口令。进度回复要说明 Codex 正在执行的实际比较，不要求用户回复；受阻时说明阻塞原因和解除条件；真正完成时说明完成范围和遗留事项，不制造额外确认循环。当环境尚未准备好而必须等待时，只显示 `已就绪`、`继续聊聊`、`取消`；用户回复 `已就绪` 后，Codex 继续实际的只读动作，不要求重复确认。

用户选择 `继续聊聊` 后，Option 保持 `discussion`、`no-write` 状态。Codex 必须暂停排队中的写入，并在任何写文件前重新检查模式和授权。SIDE-HANDOFF 或外部 Skill 的比较结果只能作为事实，Option 必须在主会话重新显示交接卡，不能直接推进 Plan 或 implementation。

## Entry handoff

When called internally without an already-confirmed `进入 option` handoff, stop at this card before invoking any exploration capability:

```markdown
**结论：当前存在需要额外探索的高成本技术分叉。**

**选项检查：**
满足“实质不同 + 无明显赢家 + 错选代价高”。

**已完成：**
Codex 已经确认 Option 的三个触发条件都满足。

**下一步：**
Codex 可以进入 Option，比较方案的成本、风险、兼容性和回滚方式；这会增加探索时间和 Token 消耗。

**请确认：**
你要不要让 Codex 先做这次额外比较？

`进入 option`

> 你同意进入 Option。Codex 接下来会比较候选方案，不会直接修改文件。

`跳过 option`

> 你不需要额外比较。Codex 会回到正常 Plan 流程，不会因为跳过 Option 而修改文件。

`继续聊聊`

> 你暂时不进入 Option，想继续讨论。Codex 会保留当前判断，回到讨论，不会开始方案比较或修改文件。

`取消`

> 你要停止当前任务。Codex 不会进入 Option、Plan 或修改文件。
```

`进入 option` is required for internal entry. The caller’s confirmed Option card satisfies this requirement; do not ask for the same confirmation a second time. An explicit direct `$option-explorer` invocation already counts as opt-in, but still requires the three conditions to be checked. If they do not hold, say why and immediately show the required next-stage handoff. When a confirmed parent route exists, return to that route’s required next stage; when the user only asked for a comparison, show the same four-choice comparison handoff with `采用 A`, `采用 B`, `继续聊聊`, and `取消`. Do not force native Plan on a comparison-only request, and do not explore or end with a reason-only paragraph.

After explicit opt-in, use only the native exploration capability actually exposed by the current host. Give each independent exploration the same task brief, constraints, decision criteria, and required evidence; keep the questions disjoint. Synthesize trade-offs, assumptions, risks, and a recommendation, then stop with this selection handoff:

```markdown
**结论：探索完成，方案取舍和推荐已列出。**

**已完成：**
Codex 已经完成探索，并列出方案 A/B 的证据、取舍和推荐。若讨论中出现新方向，先回到讨论补充证据并更新比较结果，再重新展示 A/B 选择卡。Option 只负责比较方向，不能代替 native Plan。

**下一步：**
你采用一个方向后，Codex 会回到 native Plan 或当前任务原有的执行路线；在 Plan 结果和执行授权出现前，Codex 不会修改文件。

**请回复：**
`采用 A`

> 你采用方案 A。Codex 会把这条方向带回当前任务的原路线；只有该路线需要 Plan 时才进入 native Plan，不会直接修改文件。

`采用 B`

> 你采用方案 B。Codex 会把这条方向带回当前任务的原路线；只有该路线需要 Plan 时才进入 native Plan，不会直接修改文件。

`继续聊聊`

> 你暂时不采用任何方向，想继续讨论。Codex 会保留比较结果，回到讨论，不进入 Plan 或修改文件。

`取消`

> 你要停止 Option。Codex 不会选择方案，也不会进入 Plan 或修改文件。

```

Do not present the exploration as a native Review or Plan. `采用 A`/`采用 B` records the direction and returns it to the caller’s existing route; if the user wants another direction, use `继续聊聊` to discuss it and update the comparison before showing the A/B card again. If the route requires planning, invoke callable native Plan directly or immediately return the filled manual Plan request when Plan is not callable. An independent comparison-only entry moves into task definition and Route after adoption. Do not insert another text confirmation between option selection and the required Plan input. Selection does not authorize file writes or bypass a required native Plan result. A direct Option entry remains connected to the full Workflow; after the applicable route or Plan stage, the normal implementation, verification, and completion handoffs apply. A stated preference without an explicit adoption command is not authorization.

For a direct `$option-explorer` entry, keep the Workflow active after the selection card. The next response must render the native Plan handoff or the filled manual Plan request itself; the user does not need to invoke `$task-router` or `$task-brief` again. If an external Skill was used for comparison, its output is temporary input to this Skill; do not modify that Skill or let it terminate the Workflow.

When this Workflow temporarily calls an external Skill, start with the conclusion, use subject-action-result Chinese, and return the result to the Workflow; the external Skill must not be edited.

## 真实回复写作规则

Option 的正文要直接说明“为什么要比较、每个方案差在哪里、选了以后会发生什么”：先给结论，再用 bullet 对照方案；每个动作写清主语（你或 Codex）；保留 Option、native Plan、compatibility、rollback 等关键术语，并在第一次出现时用短话说明作用。所有等待选择的卡片都保留 `继续聊聊`，它只返回讨论，不会推进到 Plan 或修改文件。不要只写“开始探索”“返回 Plan”“停止”这类没有主语和后果的状态词。

轻量中文润色（humanizer-zh）：固定技术术语可以保留，普通英文用自然中文解释；不要把多个抽象名词直译后连成一个新词。每句话写清“谁比较什么、差在哪里、选了以后会发生什么”，只改表达，不改方案事实、成本、风险或权限。

If the host does not expose a suitable native exploration capability, say so and return a compact decision frame for the user or native Plan to resolve. Never simulate Colleagues, Best-of-N, or parallel agents with a custom prompt and claim that the native capability ran.
