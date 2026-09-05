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
- Do not silently invoke a write-capable stage or skip the user’s handoff choice. When this public Skill is invoked directly, treat RCA as the current Workflow stage and return a clear next-stage handoff instead of ending with an isolated report. `$task-brief`, `$task-router`, another local Skill, and native Plan still require their own gates.
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

> The root cause may be an incomplete rule class, conflicting boundary, stale acceptance case, or missing sibling mapping. The fix should address that source and its neighboring cases, not only the sentence that exposed it.

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

RCA 的正文要让用户看懂“哪里坏了、为什么坏、影响谁、下一步做什么”：先写结论，再按证据、调用链、影响和边界分段；并列证据用 bullet；每个动作写清主语（用户、Codex、代码或测试）。保留 RCA、call path、regression 等关键术语，第一次出现时用短句解释，不把“根因已确认”“进入下一阶段”当作完整说明。

轻量中文润色（humanizer-zh）：保留 `RCA`、`call path`、`regression` 和代码标识符，但把普通英文和抽象组合改成自然中文。不要写“事务替换路径”这类直译；改写成“文本替换逻辑”或“负责替换文本的代码”。标识符后面说明它做什么，句子写出主语和结果；只改表达，不改证据、判断或权限边界。

## Handoff

When the report is complete, use one of these cards and stop. The card is the RCA stage’s handoff: it must tell the user whether the root cause is confirmed, what the next stage is, and which command selects it.

```markdown
**结论：RCA 已完成；根因、证据和影响范围已记录。**

**已完成：**
Codex 已经把现象、复现证据、调用链、根因和影响范围整理清楚。RCA（Root Cause Analysis）在这里表示“先找出问题为什么发生”，不是直接修复。

**下一步：**
你可以把结论整理成一项修复任务，也可以只保留这次分析结果。

**需要你确认：**
请决定是否继续定义修复任务。无论选择哪一项，Codex 现在都不会写文件。

**怎么回复：**
`整理 brief`

> 你要把已经确认的 RCA 结果转成修复任务。Codex 接下来会整理 Brief，再按 Route、Plan 和实施权限继续；现在不会修改文件。

`只保留结论`

> 你只需要这次 RCA 的结论。Codex 会保留分析结果并结束当前 RCA，不会进入修复或修改文件。

`继续调查`

> 你认为证据还不够。Codex 会继续做只读调查，补充复现、调用链或影响范围，不会修改文件。

`继续聊聊`

> 你暂时不决定下一步，想继续讨论这次 RCA。Codex 会保留当前分析结果，回到讨论，不会进入修复、Plan 或修改文件。

`取消`

> 你要停止当前 RCA。Codex 不会继续调查，也不会修改文件。
```

If the root cause is not confirmed, replace the next step with the missing evidence or read-only investigation and do not offer implementation as if the issue were understood. If this Skill was entered as a confirmed bug-fix route’s RCA prerequisite, return the findings to `$task-router`; the route still requires its own native Plan and execution handoff before any write. If the user invoked this Skill directly, `整理 brief` is the explicit handoff back into the full repair Workflow; `只保留结论` remains the terminal check-only branch.

For a direct `$rca-analyze` entry, treat the card above as a live Workflow handoff. After `整理 brief`, render the five-item Brief in the next response; do not ask the user to invoke `$task-brief` again. After `只保留结论`, end the RCA explicitly. If an external Skill helped collect evidence, give it only a temporary output instruction and let this Skill add the final handoff.

When this Workflow temporarily calls an external Skill, start with the conclusion, use subject-action-result Chinese, and return the result to the Workflow; the external Skill must not be edited.
