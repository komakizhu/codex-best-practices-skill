---
name: option-explorer
description: "Use when a repository task has two or more materially different viable technical paths, no obvious winner, and a costly wrong choice."
---

# Option Explorer

This is an optional decision aid, not a replacement for native Plan, Review, or implementation. Consider it only when all three trigger conditions hold:

- at least two materially different viable technical approaches exist;
- current evidence does not establish a clear winner; and
- choosing poorly would create meaningful rework, compatibility, performance, data, or architectural cost.

Do not invoke it merely because a task is Large, unfamiliar, or interesting. Before spending extra tokens, ask the user whether they want native Colleagues, Best-of-N, or parallel exploration. If they decline, continue with the normal native Plan route.

After explicit opt-in, use only the native exploration capability actually exposed by the current host. Give each independent exploration the same task brief, constraints, decision criteria, and required evidence; keep the questions disjoint. Synthesize trade-offs, assumptions, risks, and a recommendation, but do not present the exploration as a native Review or Plan and do not implement until the selected route is authorized.

If the host does not expose a suitable native exploration capability, say so and return a compact decision frame for the user or native Plan to resolve. Never simulate Colleagues, Best-of-N, or parallel agents with a custom prompt and claim that the native capability ran.
