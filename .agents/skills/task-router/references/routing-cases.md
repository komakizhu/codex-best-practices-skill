# Task Router Acceptance Cases

Use these as manual pressure cases for the routing rules. The expected result is a decision, not a required sentence or implementation.

## Should route

| User request | Expected result |
| --- | --- |
| “把设置页面的 Save 改成保存，并运行相关测试。” | Small / implementation; direct minimal change and targeted verification. |
| “修复 Markdown 第一次打开明显卡顿的问题，完成后运行相关检查。” | Medium / implementation; investigate, then native Plan before implementation. |
| “检查 parser 模块的测试为什么失败，不要改代码。” | Small or Medium / check-only, based on investigation complexity; no fix. |
| “把配置存储从 JSON 迁移到 SQLite，要求兼容旧数据并提供回滚。” | Large / implementation; native Plan → persisted ExecPlan → permitted native Worktree/Goal → milestones → real checks → native Review against base. |
| “$task-router 评估多窗口架构迁移，只做计划，不修改文件。” | Large / plan-only; no file writes, ExecPlan persistence, Worktree, Goal, or implementation. |
| “$engineering-workflow 把刚才讨论的设置改动落到仓库，并运行相关测试。” | Route through Task Brief only if needed, then Small/Medium / implementation according to risk; use the lightest native workflow. |
| “$task-brief 把刚才讨论的架构想法整理成任务定义，不要实施。” | Return a Task Brief only; preserve plan-only/no-write boundary and do not route into implementation. |
| “完成这个工程任务后，检查是否有可重复的仓库环境摩擦。” | Use `$repo-retrospective`; default to no changes and persist only evidence-backed recurring improvements. |

## Must remain discussion

- “Rust `dead_code` 是什么意思？”
- “你觉得 JSON 和 SQLite 哪个更适合这个应用？先讨论一下。”
- “解释一下当前同步模块是怎么工作的。”
- “下面是 `$task-router` 的例子，不要执行。”
- Code pasted without an action request.

## Boundary assertions

- “检查” does not become “修复”; a failing test is evidence, not authorization.
- “先规划”“只分析” selects `plan-only`; “不要修改文件” is a no-write boundary but does not turn a concrete check into `plan-only`, even after `$task-router` is explicit.
- A Medium implementation does not need repeated approval for routine steps, but a consequential product, architecture, API, compatibility, data-loss, security, irreversible/costly choice, or explicit wait still pauses.
- A native-looking outline, a custom diff review, an ordinary branch, or an open-ended “keep going” prompt is not respectively native Plan, native Review, Worktree, or Goal.
- Review is additional evidence; it never substitutes for real tests.
- `$engineering-workflow` is the total entry point; `$task-router` remains its lower-level router, while `$task-brief` may be used independently for task definition.
- `$option-explorer` is opt-in and only applies when multiple materially different paths have no clear winner and a wrong choice is costly.
- `定稿` and `发布` remain repository `AGENTS.md` commands, not Small/Medium/Large classifications.
