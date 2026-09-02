---
name: rca-analyze
description: "Use when a user merely reports a bug, unexpected behavior, failed test, or inability to invoke a Skill without explicitly asking for diagnosis or implementation, or explicitly invokes RCA; perform proportional root-cause analysis before any fix and return a repair handoff."
---

# RCA Analyze

Use this Skill for a symptom report that is not yet an authorized investigation or repair task. It is the bug-review entry for `$engineering-workflow`: establish what is broken, where the failure originates, how broad the pattern is, and what evidence supports the root cause.

## Boundary

- A report such as “这里有个 Bug”“这个 Skill 调不起来” is not permission to edit files. Keep the review read-only.
- A request such as “请检查测试为什么失败”“帮我诊断原因，只报告结果” is explicit `check-only` work. It belongs in `$task-brief`/`$task-router` with no-write authorization; RCA can be the investigation method after that route is confirmed.
- An explicit request to fix, change, implement, or complete a behavior belongs in `$task-brief` and `$task-router`. If the task is a bug fix, carry the RCA requirement into that route; explicit repair intent does not permit a symptom patch before the cause is established.
- Do not silently chain `$task-brief`, `$task-router`, another local Skill, or a native Plan. Use the handoff below and wait for the user’s next choice.
- Do not call a symptom “the root cause.” A root cause must explain the symptom, its trigger, why the existing boundary failed to catch it, and whether the same mechanism can create neighboring failures.

## Triage: Small or Large RCA

Classify the investigation, not just the number of changed files. If evidence is insufficient, keep the report in RCA rather than guessing.

- **Small RCA**: one clear symptom, one primary call path, a stable reproduction, a localized cause, low blast radius, and no evidence of a family of similar failures.
- **Large RCA**: multiple callers or modules, repeated variants of the same symptom, a missing or inconsistent rule/contract/mapping, cross-cutting behavior, unclear ownership, compatibility/data/security impact, or a repair that must cover representative cases and generalize to adjacent cases.

When in doubt between the two, use Large RCA. A rule gap such as “one sentence cannot invoke this Skill” is Large when the evidence points to incomplete language-to-Skill mapping rather than a typo in one phrase.

## RCA protocol

### 1. Capture the exact failure

Record the user’s expected behavior, actual behavior, exact input or steps, environment/session, error text, and the first observable divergence. For a Skill-invocation failure, record the requested wording, target Skill/capability, available metadata, invocation policy, parent Workflow boundary, and one comparable invocation that works.

### 2. Build a red-capable feedback loop

Create or locate the smallest unattended check that reaches the real failing seam and asserts the exact symptom: a failing test, CLI command, HTTP replay, headless-browser check, trace replay, or focused harness. Run it at least once before proposing a fix. It must be deterministic and fast enough to repeat.

If the issue is intermittent, raise the reproduction rate with a controlled loop and record the rate. If no red-capable loop can be built, stop at evidence collection, state exactly what is missing, and ask for a log, trace, fixture, environment access, or permission for temporary instrumentation. Do not proceed from an unverified theory.

### 3. Trace the failure to its source

Follow the data, control, or invocation flow backward from the symptom. Check recent changes, working examples, configuration and policy propagation, and every boundary where the input can be transformed or dropped. Compare the broken path with a working path and list the meaningful differences.

For language-driven Skill routing, inspect the complete chain rather than adding a synonym immediately:

`user wording → intent classification → Skill description/trigger match → invocation policy → parent Workflow allowlist/boundary → selected Skill`

The root cause may be an incomplete rule class, conflicting boundary, stale acceptance case, or missing sibling mapping. The fix should address that source and its neighboring cases, not only the sentence that exposed it.

### 4. Test hypotheses proportionally

- For Small RCA, form at least one falsifiable hypothesis after the evidence is collected and change one diagnostic variable at a time.
- For Large RCA, rank three to five falsifiable hypotheses, gather boundary evidence for each, and identify the invariant shared by the representative failures.

State what observation would disprove each hypothesis. For Large RCA, show the ranked hypotheses in the investigation update or report before testing them; do not block on a second approval unless a separate permission is needed. Do not edit production or repository files as a probe. Use read-only inspection, a temporary non-persistent harness, debugger/REPL inspection, or explicitly approved diagnostic instrumentation; remove temporary instrumentation before the RCA is complete.

### 5. Define scope and repair boundary

The RCA result must distinguish:

- the confirmed root cause and supporting evidence;
- the affected call paths, callers, or rule family;
- representative failing cases and at least one working/negative case when the issue is Large;
- the smallest repair boundary that addresses the cause;
- regression checks that would prove both the reported case and the neighboring pattern are fixed;
- remaining uncertainty and what evidence would resolve it.

For a Large RCA, do not fix representative symptoms one by one during analysis. First identify the common mechanism and the representative case matrix. After a separate repair confirmation, `$task-brief`/`$task-router` and the native Plan/verification stages own the implementation: lock down representative regressions, change the shared rule or source, then run the adjacent-case matrix to confirm the generalization.

## Output

Use a compact, scannable report with the appropriate level. Start with one bold sentence that says whether the root cause is confirmed and what the report permits next. Put each report label on its own bold line and put its evidence in normal text below it:

```markdown
**结论：一句话说明根因是否已确认，以及当前是否可以进入修复。**

**RCA 级别：**
Small / Large

**现象与期望：**
...

**复现/反馈回路：**
命令或测试；结果...

**证据与调用链：**
...

**根因：**
...

**影响范围：**
...

**修复边界：**
...

**回归验证：**
...

**未决问题：**
...

**代表性问题：**
Large RCA only: ...

**共性不变量：**
Large RCA only: ...

**触类旁通清单：**
Large RCA only: ...
```

For Large RCA, add `代表性问题`, `共性不变量`, and `触类旁通清单`. If the root cause is not confirmed, write `根因：尚未确认` and report the next evidence needed instead of presenting a likely cause as fact.

## Handoff

When the report is complete, use one of these cards and stop:

```markdown
**结论：RCA 已完成；根因、证据和影响范围已记录。**

**已完成：**
RCA 已完成。

**下一步：**
回到 `$task-brief` 定义修复任务，或保留 RCA 结论。

**需要你确认：**
是否把这次分析转成授权的修复任务；当前不写文件。

**怎么回复：**
- `整理 brief`：进入修复任务定义
- `只保留结论`：结束 RCA
- `继续调查`：补充 RCA 证据
- `取消`：停止
```

If the root cause is not confirmed, replace the next step with the missing evidence or read-only investigation and do not offer implementation as if the issue were understood. If this Skill was entered as a confirmed bug-fix route’s RCA prerequisite, return the findings to `$task-router`; the route still requires its own native Plan and execution handoff before any write.
