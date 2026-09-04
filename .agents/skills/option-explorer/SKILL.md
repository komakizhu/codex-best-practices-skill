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

## Entry handoff

When called internally without an already-confirmed `进入 option` handoff, stop at this card before invoking any exploration capability:

```markdown
**结论：当前存在需要额外探索的高成本技术分叉。**

**选项检查：**
满足“实质不同 + 无明显赢家 + 错选代价高”。

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
```

`进入 option` is required for internal entry. The caller’s confirmed Option card satisfies this requirement; do not ask for the same confirmation a second time. An explicit direct `$option-explorer` invocation already counts as opt-in, but still requires the three conditions to be checked. If they do not hold, return the compact reason and immediately show the required next-stage handoff (normally native Plan or the filled manual Plan request); do not explore or end with a reason-only paragraph.

After explicit opt-in, use only the native exploration capability actually exposed by the current host. Give each independent exploration the same task brief, constraints, decision criteria, and required evidence; keep the questions disjoint. Synthesize trade-offs, assumptions, risks, and a recommendation, then stop with this selection handoff:

```markdown
**结论：探索完成，方案取舍和推荐已列出。**

**探索完成：**
Codex 已经列出方案 A/B（或更多方案）的证据、取舍和推荐。Option 只负责比较方向，不能代替 native Plan。

**下一步：**
你选择一个方向后，Codex 会回到 native Plan 或执行路线；在 Plan 结果和执行授权出现前，Codex 不会修改文件。

**请回复：**
`选择 A`

> 你选择方案 A。Codex 会用这个方向进入下一步 Plan，不会直接修改文件。

`选择 B`

> 你选择方案 B。Codex 会用这个方向进入下一步 Plan，不会直接修改文件。

`A`

> 你用简写选择方案 A。Codex 会把它当作“选择 A”，然后进入下一步 Plan。

`B`

> 你用简写选择方案 B。Codex 会把它当作“选择 B”，然后进入下一步 Plan。

`回到 Plan`

> 你不再比较其他方案。Codex 会回到 Plan，继续制定实施步骤。

`继续聊聊`

> 你暂时不选择方案，想继续讨论。Codex 会保留当前比较结果，回到讨论，不会进入 Plan 或修改文件。

`取消`

> 你要停止 Option。Codex 不会选择方案，也不会进入 Plan 或修改文件。
```

Do not present the exploration as a native Review or Plan. A selected option authorizes the direction and the next required planning stage: invoke callable native Plan directly, or immediately return the filled manual Plan request when Plan is not callable. Do not insert another text confirmation between option selection and the Plan input. Selection does not authorize file writes or bypass the required native Plan result. A direct Option entry remains connected to the full Workflow; after the Plan stage, the normal implementation, verification, and completion handoffs apply.

## 真实回复写作规则

Option 的正文要直接说明“为什么要比较、每个方案差在哪里、选了以后会发生什么”：先给结论，再用 bullet 对照方案；每个动作写清主语（你或 Codex）；保留 Option、native Plan、compatibility、rollback 等关键术语，并在第一次出现时用短话说明作用。所有等待选择的卡片都保留 `继续聊聊`，它只返回讨论，不会推进到 Plan 或修改文件。不要只写“开始探索”“返回 Plan”“停止”这类没有主语和后果的状态词。

轻量中文润色（humanizer-zh）：固定技术术语可以保留，普通英文用自然中文解释；不要把多个抽象名词直译后连成一个新词。每句话写清“谁比较什么、差在哪里、选了以后会发生什么”，只改表达，不改方案事实、成本、风险或权限。

If the host does not expose a suitable native exploration capability, say so and return a compact decision frame for the user or native Plan to resolve. Never simulate Colleagues, Best-of-N, or parallel agents with a custom prompt and claim that the native capability ran.
