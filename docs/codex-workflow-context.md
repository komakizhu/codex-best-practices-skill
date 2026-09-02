# Codex Workflow Context

This is the lightweight handoff context for continuing the Codex workflow design in GPT Work. It records the current conclusions, not the full conversation.

## Core Direction

The workflow should be **native-first and human-confirmed**. Custom Skills should not reimplement Codex-native capabilities such as Plan, Review, Worktree, Goal, Colleagues/reviewer/subagent workflows, or the repository's own test/build/lint/typecheck commands.

Use custom Skills only for orchestration gaps: turning natural-language intent into a clear engineering task, routing by complexity, reviewing symptom-only Bugs through proportional RCA, matching a suitable local discussion Skill, optionally comparing materially different technical approaches, and improving the repository environment after real friction is observed. Every transition must be visible; permission-requiring, costly, write-capable, or native stages require confirmation, while a safe read-only discussion/RCA stage may auto-start after a visible notice when the user’s intent is explicit.

Keep the system lightweight. Avoid duplicated rules, unnecessary gates, large persistent context, or a custom framework that competes with native Codex features.

### Runtime source of truth

On the current local host, Codex loads installed Skills from `~/.codex/skills`; the repository’s `.agents/skills` tree is the versioned maintenance copy and is not automatically loaded by the CLI. A Skill change must therefore be synchronized to both locations, then used in a new or reloaded session. Do not add an unsupported `hidden` or `visibility` key while doing so: the available metadata controls UI labels and invocation policy, not per-Skill host-chip visibility.

### Human handoff protocol

Every handoff starts with one bold, single-sentence conclusion. After that, use the four semantic fields `已完成`、`下一步`、`需要你确认`、`怎么回复`; each field name occupies its own bold line, its details use normal text, and each reply command gets its own list item. Route, mode, type, and restrictions are separate metadata lines. The standard replies are:

- `确认` / `确认路由` — accept the current handoff only.
- `修改：...` — correct the current handoff and regenerate it.
- `进入结构化探索` / `继续讨论` / `整理 brief` — choose structured ideation, ordinary discussion, or the boundary back to a task brief when the idea is still exploratory.
- `继续普通讨论` / `停止当前 Skill` — leave an automatically selected local discussion Skill or return to ordinary discussion.
- `开始该模式` — enter a user-only local helper when the Workflow has explicitly handed it off; the helper name stays out of normal progress text.
- `进入 option` / `跳过 option` — opt into or decline extra technical exploration.
- `整理 brief` / `只保留结论` / `继续调查` — turn a completed RCA into a repair brief, end after analysis, or continue read-only evidence gathering.
- `确认计划，执行` — accept the native Plan and permit the authorized implementation stage; `执行` is a context-specific shorthand only when the current card explicitly asks for plan approval.
- `进入复盘` / `跳过复盘` — enter or skip the optional repository retrospective after Medium/Large completion; `复盘` / `跳过` are context-specific short forms.
- `Plan 已完成` — return after the user has actually completed a host-native `/plan` when the current host could not invoke it, with the native result visible or returned; a bare phrase is not sufficient.
- `确认写入` / `只记录` — accept or decline a proposed retrospective change.
- `取消` — stop the active Workflow without entering the next stage.

### Native Plan boundary

Native Plan is a host capability, not a prompt-created Skill mode. `update_plan` is a checklist/progress tool and does not enter or exit native Plan. When a callable native Plan is unavailable, the Workflow may provide a user-run `/plan` handoff only when the host explicitly exposes or confirms that command. The handoff must include a filled `Plan 请求` with this fixed field order: `任务目标`, `已确认的 RCA/证据`, `范围`, `非目标`, `约束`, `验收与验证`, followed by `请只制定 native Plan，不修改文件、不执行实现、不提交。` If `/plan` is not confirmed, report the missing capability and stop rather than issuing an unverified command or simulating a Plan.

The user-run fallback is complete only when the native Plan result is observable in the current conversation or returned by the user. `Plan 已完成` without that result does not authorize the next stage or any write.

## Current AGENTS.md Direction

`AGENTS.md` is the long-lived project rule layer. It should stay short and stable rather than becoming a project diary.

Current principles:
- Prefer coherent prose over fragmented AI-style formatting.
- The user's current instruction defines scope.
- Discussion, inspection, analysis, review, or planning does not authorize implementation.
- Symptom-only Bug reports enter read-only RCA; explicit check/diagnosis requests enter `check-only`; no Bug fix is written before its root cause is established.
- Explicit limits such as “只分析”, “只做计划”, “不要修改文件”, or “只检查” always take precedence.
- Verification windows should stay in the background or PiP when possible unless explicitly requested otherwise.
- Engineering workflows are command-gated and must not activate during casual discussion.
- Prefer Codex-native Plan, Goal, Review, Worktree, Colleagues/reviewer/subagent capabilities whenever available.
- Never claim a native mode, reviewer, Worktree, Goal, Colleague, or UI action was used unless it actually succeeded.
- After engineering work, run relevant verification, show `git status` and a concise diff summary, then stop.
- `定稿` means local finalization: commit if needed and merge into local `main`.
- `发布` means publish to GitHub and merge into remote `main`.
- Do not add hashes, frozen contracts, baselines, gates, or similar machinery without a concrete failure mode that ordinary Git, versioning, constraints, types, transactions, or tests cannot adequately prevent.

The old direct `task-router` entry should eventually be replaced by a higher-level orchestration entry.

## Target Skill Architecture

```text
AGENTS.md
    ↓
$engineering-workflow
    ├── intent + local Skill match
    │   ├── auto: internal ideation / grilling helper (clear intent)
    │   └── user-only handoff: disabled local helpers
    ├── exploration gate
    │   ├── ordinary discussion
    │   └── 结构化探索 (auto on clear intent; otherwise opt-in)
    ├── symptom-only Bug report → $rca-analyze (read-only RCA)
    ├── $task-brief (action-ready or 整理 brief)
    ├── $task-router
    ├── $option-explorer   (optional)
    └── $repo-retrospective
            ↓
Codex native capabilities
Plan / Review / Colleagues / Worktree / Goal / Tests
```

### `$engineering-workflow`

Main orchestration entry. Dormant during ordinary discussion. Activates only when explicitly invoked; a clear repository request without the invocation remains ordinary host handling.

Keep it thin. First separate an exploratory idea, a symptom-only Bug report, and action-ready work, then match a suitable local helper from the current session. A clear request for a safe, model-invocable discussion or read-only RCA stage may be auto-started after a visible generic notice; a user-only, high-cost, write-capable, or ambiguous helper gets a short handoff instead. Exploratory input must not cause a five-item brief to be rewritten after every sentence. A symptom-only Bug report goes to `$rca-analyze` and does not become a repair brief. When the user says `整理 brief`, or the request is already action-ready, synthesize one brief snapshot, then route it to the right workflow, optionally offer solution exploration when a high-value technical fork exists, and offer—not automatically run—a lightweight repository retrospective at the end.

It must not reimplement native Codex workflows. It must show a handoff and wait after the brief, after routing, after a completed RCA before repair, before Option, after Option, after native Plan, and before optional retrospective entry. Exploration has its own short handoff and does not enter Router, Plan, or execution until the user explicitly chooses `整理 brief` and confirms the resulting brief. A local Skill’s own hard gates remain authoritative, and the Workflow never auto-chains multiple local Skills.

### Local Skill matching

Inspect the current session’s available Skills and frontmatter before selecting one; never invent a name or claim an invocation that did not succeed. Use at most one local Skill at a time:

- clear ideation intent (`头脑风暴`, “帮我想方案”, “比较几个方向”) → auto-start an available ideation helper after a generic `结构化探索` notice; its design-approval gate still applies, and any later design-document write needs separate permission;
- explicit relentless-question intent (“多问我”, “逐个拷问”) → prefer the enabled model-invocable `grill-me` wrapper, falling back to `拷问底层模式` when unavailable; use one question at a time;
- a local Skill with `disable-model-invocation: true` → user-only; do not auto-start, and provide a generic entry plus a model-invocable alternative;
- a symptom-only Bug report → use the available `$rca-analyze` route for read-only root-cause analysis; do not treat it as an implementation request;
- no clear match or multiple equally good matches → ordinary discussion or a short choice handoff.

The auto-call notice names the public capability, why it matches, its discussion/no-routing boundary, and the escape replies `继续普通讨论` / `停止当前 Skill`. Normal output names only `$engineering-workflow`, `$task-brief`, `$task-router`, `$rca-analyze`, `$option-explorer`, and `$repo-retrospective`; helper names remain internal unless the user explicitly asks. A local helper or RCA call never grants routing, Plan, execution, or writes by itself; if it later proposes a document or other side effect, use a separate confirmation. After it returns, reassess intent rather than silently chaining another helper or entering `$task-brief`.

A symptom-only Bug report is not action-ready: enter read-only `$rca-analyze`. An explicit request to check, diagnose, investigate, review, or explain a failure without changing files is action-ready `check-only` and enters Task Brief/Router first. Every Bug implementation records a confirmed root cause before writing. Small RCA is proportional and localized; Large RCA must cover representative cases and the shared rule, such as a missing family of language-to-Skill invocation mappings.

For a user-only Skill, use a four-line handoff with `开始该模式` as the entry, `用<可模型调用替代>` as the fallback, and `继续普通讨论` / `取消` as exits. Repeat the exact helper name only when the user already named it and needs the invocation string. Do not claim that a disabled Skill was auto-invoked.

### `$task-brief`

Turns action-ready, conversational, incomplete, or scattered intent into one engineering task definition with five visible items after any appropriate local exploration Skill. It is a snapshot, not a live transcript and not a brainstorming loop.

When a Bug has already passed through RCA, carry its confirmed evidence, root cause, affected pattern, representative cases, and regression matrix into the brief. A symptom-only report must not enter this Skill before that RCA/repair-intent boundary.

Core fields:
- Goal
- Context
- Constraints
- Non-goals
- Acceptance

Optional:
- References
- Open questions

It should primarily summarize information already present in the conversation. Do not behave like an interview bot. Ask at most one important clarification when missing information would materially change implementation direction. Its fifth item must include the brief confirmation instructions.

The user may explicitly call this after discussing a feature. When `$engineering-workflow` is invoked directly, it still displays the brief and waits for `确认`, `修改：...`, `先聊一聊`, or `取消` before routing.

If the user says `先聊一聊`, `还没想好`, or adds an exploratory fragment, keep the last brief as `暂存草案（未确认）` and return to the Workflow Exploration mode; do not treat that input as a brief correction. `整理 brief` is the explicit boundary that asks for one new synthesis.

### `$task-router`

Determines authorization mode and task complexity, then shows a route handoff and waits before the next stage.

Authorization modes:
- `implementation`
- `check-only`
- `plan-only`

Never upgrade check-only or plan-only into implementation without user authorization.

For any Bug implementation, root-cause analysis is a mandatory pre-write condition. Small Bugs use a focused RCA; systemic Bugs use full RCA with representative cases and a generalization boundary. A failing test or plausible explanation is evidence, not a confirmed root cause.

Classify Small / Medium / Large based on uncertainty, risk, blast radius, rollback difficulty, architecture/compatibility/data impact, and validation complexity. Do not classify mainly by file count or lines changed.

Small: clear implementation path, localized, low-risk, directly verifiable.

Preferred flow:
```text
minimal investigation
→ minimal change
→ real verification
→ inspect diff
→ git status + concise diff summary
→ stop
```

Do not force Plan, Worktree, Goal, or formal Review for routine Small tasks.

Medium: ordinary bugs, multi-file features, behavior changes, performance/concurrency issues, or moderate refactors.

Medium implementation must complete the host’s actual native Plan after read-only investigation and before any file write. If native Plan is unavailable, use the capability-aware `$task-router` handoff: issue a filled `Plan 请求` only when the host confirms user-run `/plan`, otherwise report the missing entry and stop. A short internal outline or `update_plan` is not a substitute. Require the actual native result before accepting `Plan 已完成`; for `check-only` or `plan-only`, report the result without entering implementation.

After implementation, always run real project verification. Use native Review/Colleagues reviewer when the change has meaningful logic, regression, concurrency, performance, or multi-module risk. Do not force heavyweight Review for low-risk Medium changes. After native Plan, implementation waits for the user’s execution confirmation.

Large: migrations, persistence format changes, core architecture changes, protocol/public API migrations, cross-subsystem work, multi-stage changes, rollback-sensitive work, or tasks requiring durable state.

Large should normally use native Plan and a persisted ExecPlan. If native Plan is unavailable, follow the capability-aware `$task-router` handoff; only a host-confirmed user-run `/plan` receives a filled `Plan 请求`, otherwise report the missing entry and stop. Worktree and Goal are conditional, not automatic.

Use Worktree when isolation, parallelism, long-running experimentation, or a large working-tree blast radius makes isolation valuable.

Use Goal when the task has a clear outcome, measurable completion criteria, a repeatable validation loop, and can progress autonomously. Do not force Goal when multiple major human decisions are expected midstream.

Large changes should normally receive native Review against `main` or the correct baseline branch. Before writing after Plan, show the execution handoff with ExecPlan, Worktree, Goal, migration, rollback, and milestone choices.

### `$rca-analyze`

Read-only Bug-review entry for symptom-only reports and an optional full-RCA stage for systemic Bugs. Explicit check/diagnosis requests enter `$task-brief`/`$task-router` as `check-only` and may use this RCA protocol during their read-only investigation. Small RCA confirms the exact failure, evidence, call path, and localized cause. Large RCA identifies representative failures, the shared mechanism, the generalization boundary, and adjacent regression checks. It never silently fixes or enters `$task-brief`; after a confirmed cause, the user chooses `整理 brief`, `只保留结论`, or `继续调查`. A Bug-fix task that was explicitly authorized may use the same RCA protocol as its mandatory pre-write investigation.

## `$option-explorer`

Optional Skill for high-value technical forks. It should not run by default and should never be tied mechanically to Large tasks.

Consider it only when:
1. there are two or more materially different viable technical paths;
2. there is no obvious winner;
3. choosing the wrong direction has meaningful cost.

Before using native Colleagues / Best-of-N / parallel exploration, ask whether the user wants the extra token/cost expenditure. If the user declines, continue with normal Plan.

After exploration, show the recommendation and wait for `选择 A/B` or `回到 Plan`; choosing a direction does not bypass the next native Plan handoff or authorize writes.

## `$repo-retrospective`

Optional, user-confirmed end-of-task repository/environment review. Its purpose is to support the principle of iteratively improving the Codex development environment.

It must not modify `AGENTS.md` after every task.

Look for real friction such as:
- repeatedly guessing test/build commands;
- unclear startup scripts;
- undocumented environment variables;
- CI/local command mismatch;
- the same special build parameter being rediscovered;
- stale `AGENTS.md` rules;
- repeated manual checks that should become scripts/tests.

Default behavior: do not enter it automatically. For Medium/Large completion, show the user `进入复盘` / `跳过复盘`; for Small, offer it only when real recurring friction was observed or requested.

Persist something only when all or most are true, and only after the user confirms the proposed write:
1. the issue caused real rework, error, or repeated investigation;
2. it is likely to happen again;
3. a small, stable improvement can prevent it.

Preferred persistence target:
```text
machine-checkable behavior → tests / scripts / CI
stable project-wide rule   → AGENTS.md
reusable workflow          → Skill
architecture knowledge     → docs/
large-task state           → ExecPlan
one-off or unverified issue→ do not persist
```

Keep context efficient. Do not turn `AGENTS.md` into a task log.

## Native-First Principle

Whenever Codex already has an appropriate native capability, use it instead of recreating it in a Skill.

- planning → native Plan; user-run `/plan` only when the host confirms it
- code review → native Review / `/review` or Colleagues reviewer
- isolation → native Worktree
- long-running closed-loop execution → native Goal / `/goal`
- parallel investigation → native Colleagues/subagents where appropriate
- verification → the repository's real test/build/lint/typecheck/benchmark commands

Custom Skills should route to these capabilities, not imitate them.

## Task Brief / GitHub-Issue Style

The user should not have to manually write a formal issue every time. `$task-brief` should compile natural conversation into a concise brief containing the useful subset of:

- Goal
- Context
- Constraints
- Non-goals
- Acceptance
- References
- Open questions

Do not invent requirements the user did not provide.

If a missing detail would fundamentally change implementation direction, ask one concise question. Otherwise proceed using repository evidence and the existing conversation.

## ExecPlan Principle

Large tasks must not rely only on chat history.

Persist the confirmed long-running plan in the repository using the repository's existing convention, or a location such as:

`docs/exec-plans/YYYY-MM-DD-<task>.md`

An ExecPlan should be a living document and may include:
- Goal
- Non-goals
- Current state
- Scope / constraints
- Risks
- Milestones
- Validation per milestone
- Migration / compatibility strategy
- Rollback
- Progress
- Discoveries
- Decisions
- Final acceptance criteria
- Stop / escalation conditions

Update Progress, Discoveries, and Decisions during execution. Do not persist or invoke the retrospective solely because a task reached completion; the user’s handoff response controls that transition.

## Alignment Notes

Strongly aligned with OpenAI guidance or mature agent-engineering practice:
- use `AGENTS.md` for durable repository context;
- make tasks clear and bounded, similar to good GitHub Issues;
- improve the development environment iteratively instead of repeatedly fixing prompts;
- use real tests and execution, not model confidence;
- use persistent repository state for long-running work;
- use isolation/worktrees when they add real value;
- prefer fresh/independent review for risky changes;
- use Best-of-N / parallel exploration only when decision value justifies cost;
- keep workflows proportional to risk.

Local workflow conventions rather than OpenAI standards:
- Small / Medium / Large classification;
- `$engineering-workflow` / `$task-router` orchestration design;
- exact `定稿` and `发布` semantics;
- specific command-gating language;
- anti-overengineering rules around gates/hashes/baselines.

Keep this distinction explicit in future documentation.

## Current Maintenance Note

The workflow is now organized as a human-confirmed chain: intent/local-Skill match (safe discussion or read-only RCA may auto-start after notice) → exploration or symptom-only Bug review → action-ready brief → route → RCA/investigation/Option decision → capability-aware native Plan handoff → execution → verification/Review → optional retrospective. Future changes should update the relevant Skill and its acceptance cases together. Existing business code is out of scope, and no commit or publish occurs unless explicitly requested with `定稿` or `发布`.

Use this file as the compact baseline context for future GPT Work sessions. Update it only when the workflow architecture or long-lived rules materially change.
