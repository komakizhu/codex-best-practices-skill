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
进入 `$option-explorer`，预计增加探索时间/Token。

**请确认：**
现在是否进入 Option？

- `进入 option`：开始探索
- `跳过 option`：回到正常 Plan
```

`进入 option` is required for internal entry. The caller’s confirmed Option card satisfies this requirement; do not ask for the same confirmation a second time. An explicit direct `$option-explorer` invocation already counts as opt-in, but still requires the three conditions to be checked; if they do not hold, return the compact reason and do not explore.

After explicit opt-in, use only the native exploration capability actually exposed by the current host. Give each independent exploration the same task brief, constraints, decision criteria, and required evidence; keep the questions disjoint. Synthesize trade-offs, assumptions, risks, and a recommendation, then stop with this selection handoff:

```markdown
**结论：探索完成，方案取舍和推荐已列出。**

**探索完成：**
方案 A/B（或更多）及其证据、取舍和推荐已列出。

**下一步：**
等待你选择方案，再回到所需的 native Plan/执行路线。

**请回复：**
- `选择 A`：选择方案 A
- `选择 B`：选择方案 B
- `A`：使用简写选择方案 A
- `B`：使用简写选择方案 B
- `回到 Plan`：返回 Plan
- `取消`：停止
```

Do not present the exploration as a native Review or Plan. A selected option authorizes the direction only; after selection, return to the next native Plan handoff and wait for `确认进入 Plan` before entering it. It does not authorize file writes or bypass a required native Plan.

If the host does not expose a suitable native exploration capability, say so and return a compact decision frame for the user or native Plan to resolve. Never simulate Colleagues, Best-of-N, or parallel agents with a custom prompt and claim that the native capability ran.
