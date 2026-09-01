---
name: engineering-workflow
description: "Use when the user explicitly invokes `$engineering-workflow` to summarize and route a repository engineering task; do not activate from an ordinary repository request, discussion, explanation, brainstorming, hypothetical design, read-only understanding, or pasted code."
---

# Engineering Workflow

This is a dormant, native-first entry point for repository engineering work. It is activated only by an explicit user invocation, first separates exploration from action-ready work, can match a suitable local discussion Skill, then coordinates task definition and routing before handing execution to the host’s native Codex capabilities and the repository’s `AGENTS.md`. The workflow is human-confirmed at consequential skill/native-stage handoffs; safe local discussion Skills may be auto-invoked after a visible notice.

## Boundary

Activate only when the user explicitly invokes `$engineering-workflow`. A clear request to change, test, investigate, review, or otherwise perform a concrete action in the current repository does not activate this Skill by itself. Do not activate for ordinary conversation, explanations, brainstorming, architecture discussion, hypothetical questions, read-only understanding, or pasted code without execution intent.

Once explicitly activated, keep this workflow active for the current engineering task through completion. Interpret urgency and implementation wording—such as “直接修”“马上做”“不要再问” or “跳过计划”—as task intent or authorization, never as permission to skip a required stage. End the active workflow early only when the user explicitly asks to exit, cancel, or stop using `$engineering-workflow`; do not treat an implicit change of tone as cancellation. The invocation itself does not grant write permission: the request still determines `implementation`, `check-only`, or `plan-only`.

## Intent gate

Before invoking `$task-brief`, classify the current conversation:

- **Exploration** — the user has a vague idea, says “先聊一聊”“帮我想想”“还没想好”“看看可不可行”, asks for discussion/brainstorming, or has not yet named an actionable repository change, check, or plan. Do not create or update a five-item brief. Native Plan is not an exploration tool.
- **Action-ready** — the user has a concrete repository outcome, check, investigation, or plan request. Enter `$task-brief`.
- **Mixed** — the user has a vague idea but also says “直接做/实现”. Do not guess whether to explore or execute; show a choice card and wait for `进入探索` or `整理 brief`.

For Mixed, use this compact choice card and stop:

```text
当前判断：想法仍在探索，但你也提到了实施请求。
下一步：可以先探索，也可以整理成 action-ready brief。
需要你确认：选择是否先讨论；未选择前不进入 Router、Plan 或执行。
怎么回复： “进入探索”先讨论；“整理 brief”直接定义任务；“取消”停止。
```

If the user explicitly says `先聊一聊`, `还没想好`, `先别整理`, or equivalent at any point before the brief is confirmed, switch to Exploration immediately. Freeze any displayed brief as `暂存草案（未确认）`; do not regenerate it from each new message and do not treat later idea fragments as brief corrections.

For Exploration, show this short handoff and stop:

```text
已完成：已识别为探索性想法，暂不生成或更新 brief。
下一步：可以普通讨论，或进入「结构化探索」梳理目标、场景、约束和候选方向。
需要你确认：选择探索方式；确认前不进入 Router、Plan 或执行。
怎么回复： “进入结构化探索”开始；“继续讨论”直接聊；“整理 brief”回到任务定义；“取消”结束。
```

When Exploration is active, each response must add useful reasoning—such as a new hypothesis, trade-off, risk, example, or a focused next question—and may ask only one question at a time. Do not merely paraphrase the latest sentence and do not output a revised brief. If the user clearly asks to brainstorm, generate ideas, or compare possible directions, follow the Local Skill matching rules below; otherwise ordinary discussion stays ordinary discussion. When the user chooses `整理 brief`, summarize the accumulated conversation once through `$task-brief`, then use the normal five-item confirmation gate.

For Action-ready work, inspect the current conversation and repository context through `$task-brief` and display a five-item brief: `目标`, `当前上下文/证据`, `约束与授权`, `范围/非目标`, and `验收标准/待确认项`. Do not silently form or skip this brief when the task is Action-ready. The fifth item must end with the brief handoff: `请确认以上 brief；回复“确认”继续路由，回复“修改：...”重写完整 brief，回复“先聊一聊”冻结草案并进入探索，回复“取消”停止。` Stop there. Do not invoke `$task-router`, native Plan, or modify files before confirmation. A post-brief response such as “确认”“按这个做” or “直接修” confirms only the brief and the requested authorization mode; `先聊一聊` is a mode switch, not a request to rewrite the brief, and no reply can bypass a later handoff or required native stage.

Keep the user’s authorization boundary intact. The workflow has exactly one mode: `implementation`, `check-only`, or `plan-only`. Never turn a check into a fix, or a plan into implementation.

## Public Skill surface

The only Skills named in normal user-facing callouts, handoffs, progress updates, and completion summaries are this Workflow and its four orchestration children:

- `$engineering-workflow`
- `$task-brief`
- `$task-router`
- `$option-explorer`
- `$repo-retrospective`

All other local Skills are internal helpers. They may provide the discussion or clarification behavior selected by this Workflow, but describe that behavior publicly as `结构化探索`、`逐项澄清` or `内部分析`; do not echo the helper’s Skill name or UI display name. This is an output-level allowlist. The local Skill metadata currently supports display names and invocation policy, but no supported `hidden` or `visibility` field; if the host itself renders a Skill chip or invocation event, do not claim that this rule hides that host chrome. If the user explicitly asks which helper is running, answer truthfully.

## Local Skill matching

After the Intent gate and before falling back to a brief or ordinary discussion, inspect the current session’s available local Skills and their frontmatter. Use only a Skill that is actually available; never invent an invocation or claim that a Skill ran unless its invocation succeeded. Local Skill matching does not grant implementation, file-write, native Plan, Router, Option, or retrospective authorization.

Use the clearest matching Skill, at most one at a time:

- **Idea exploration** — for “帮我想方案”“头脑风暴”“比较几个方向” or a vague idea where the user clearly asks for new directions, auto-invoke the available `头脑风暴` Skill. It is conversation-first and model-invocable; its own design-approval gate still applies, and any later design-document write or next Skill needs its own permission.
- **Relentless specification questions** — for “多问我”“逐个拷问”“把所有分支问清楚”, prefer the available model-invocable `grill-me` / `无代码库拷问` wrapper; if it is unavailable, use the model-invocable `拷问底层模式` fallback. Ask one question at a time, state the recommended answer, and wait for the user; the explicit request itself is the mode authorization.
- **User-only local Skills** — inspect the matched Skill’s own `disable-model-invocation: true` flag. Do not auto-invoke a disabled Skill or substitute another Skill while claiming it is the requested one. If the user names one, use a compact generic handoff and wait for its explicit entry; otherwise offer a model-invocable capability or ordinary discussion.

For an automatic local discussion Skill, show this notice before invoking it in the same response:

```text
即将进入：<公开的讨论方式>
原因：你的当前意图与它的触发条件匹配
边界：先做讨论/澄清，不更新 brief、不进入 Router/Plan/执行；后续若要写文档或调用下一 Skill，会另行说明并确认
切换：下一轮可回复“继续普通讨论”或“停止当前 Skill”返回
```

For an internal helper, `<公开的讨论方式>` must be a capability label such as `结构化探索` or `逐项澄清`, not the helper’s Skill name. The names of the five public Skills above may be shown when one of them is the actual next stage.

For a user-only Skill, use this handoff instead of trying to invoke it:

```text
已完成：已匹配一个需要用户显式启动的本地辅助模式。
下一步：等待你的明确入口，或改用 <可模型调用替代>。
需要你确认：是否进入这条高强度/特定流程；当前不进入 Router、Plan 或执行。
怎么回复： “开始该模式”进入；“用<可模型调用替代>”改用替代；“继续普通讨论”或“取消”退出。
```

Only when the user has already explicitly named a user-only Skill and needs an exact invocation string may the Workflow repeat that name; this exception is an entry instruction, not a normal progress label.

Do not emit this notice and then wait for a second confirmation when the user has already made the Skill intent explicit; that would turn automatic matching back into the missing handoff. For a merely possible match, or any Skill that is user-only, high-cost, writes a document, delegates work, or changes the conversation mode without explicit intent, use the four-line handoff and wait. Auto-starting a conversation-first Skill authorizes only its discussion phase; any later write, delegation, cost, or next-Skill transition still uses the applicable confirmation. After a local Skill returns, re-evaluate the intent; do not automatically chain another Skill or jump to `$task-brief` until the user asks to `整理 brief` or gives an action-ready request.

## Handoff contract

Every permission-requiring transition from one Skill or native stage to another must use one compact handoff card. Safe, model-invocable local discussion Skills may use the visible auto-call notice above when the user’s intent is explicit; all other transitions must state, in this order:

```text
已完成：      the stage just completed and its evidence
下一步：      the exact Skill or native capability that would run next
需要你确认：  the decision or permission needed now
怎么回复：    the shortest accepted replies and what each one does
```

Stop after a permission card. Do not silently invoke the named next stage. `确认` confirms only the current card; it is not blanket permission for later Option exploration, Plan approval, file writes, Worktree, Goal, Review, or retrospective. When the current card explicitly asks for plan execution, `执行` is accepted as a shorthand for `确认计划，执行`; when it explicitly asks about closeout, `复盘` and `跳过` are accepted as shorthands for the named retrospective choices. `修改：...` revises the current handoff, and `取消` ends the active Workflow without starting the next stage.

An Exploration handoff is different from a task correction: `先聊一聊`/`进入探索` freezes the current brief, `进入结构化探索` explicitly selects the ideation capability, and `整理 brief` is the only reply that resumes task definition. If the user already clearly asks for brainstorming, the Workflow may auto-call it with the notice above; until a local Skill or ordinary discussion returns to action-ready intent, do not route, plan, write, or call Option Explorer. A local Skill’s later document or implementation step still needs the applicable confirmation.

After a confirmed handoff, routine read-only investigation, implementation, verification, and progress updates may continue within the selected route. Pause again for a consequential product, architecture, API, compatibility, data-loss, security, irreversible/costly decision, native capability requiring a user/UI action, or any explicit user request to wait.

## Composition

1. Apply the Intent gate and Local Skill matching before `$task-brief`. Clear requests for a safe, model-invocable discussion Skill may auto-call it with a notice; ambiguous exploration gets ordinary discussion or a handoff; only Action-ready work gets a five-item brief.
2. For Action-ready work, use `$task-brief` and stop for the explicit brief confirmation, correction, Exploration switch, or cancellation.
3. After brief confirmation, use `$task-router`. Display its route handoff and stop for `确认路由` (or `修改：...` / `取消`) before investigation or any native stage. A direct `$task-router` invocation skips only the Workflow brief gate; it still receives this route handoff.
4. After the confirmed route’s necessary read-only investigation, explicitly report the Option trigger check. If all three Option conditions hold, stop and ask `进入 option` or `跳过 option`; never invoke `$option-explorer` silently. If the conditions do not hold, say `Option 不触发` and name the next stage, then wait for `确认继续`.
5. Use `$option-explorer` only after `进入 option`. After exploration, stop with the candidates, trade-offs, recommendation, and exact next step; wait for `选择 A`, `选择 B`, `回到 Plan`, or `取消`. A selected option authorizes the direction only. After a selection, show the native Plan handoff and wait again before entering Plan or implementation; it never permits a file write by itself.
6. Execute the native stages required by the route. Small implementation may proceed directly after the route handoff; Medium and Large implementation must complete the host’s actual native Plan before the first file modification. For `check-only` or `plan-only`, report the native result and stop without an execution confirmation. For `implementation`, after native Plan stop with a concise plan handoff and wait for `确认计划，执行` (or `修改计划` / `取消`) before writing. For Large, include any proposed Worktree, Goal, ExecPlan persistence, migration, rollback, and milestone choices in that same execution handoff; ask separately only when a native capability requires a user/UI action. Never recreate Plan, Review, Goal, Worktree, Colleagues, or a test framework inside a Skill.
7. After implementation, real verification, and any required Review finish, display a completion handoff containing result, checks, review status, actual diff/status, and unresolved items. For Medium/Large work, stop and ask `进入复盘` or `跳过复盘`; do not invoke `$repo-retrospective` automatically. For Small work, offer it only when real recurring repository friction was observed or the user asks for it. The final task summary is always delivered; retrospective is an optional additional stage.
8. Follow `AGENTS.md` for real verification, `git status`, concise diff summary, and stopping. Never commit or publish automatically.

This Skill does not implement planning, review, goals, worktrees, colleague orchestration, or a test framework. It connects the routing skills, can dispatch an available internal discussion helper under the rules above, presents explicit handoffs where permission matters, and preserves every Skill’s own boundaries.

For the Medium/Large closeout, use this compact card:

```text
已完成：    实现、真实验证、Review，以及 git status/diff 摘要
下一步：    可选的 $repo-retrospective；最终任务摘要已经给出
需要你确认：是否检查可重复的仓库环境摩擦
怎么回复：  “进入复盘”开始；“跳过复盘”直接结束；“取消”停止当前 Workflow
```
