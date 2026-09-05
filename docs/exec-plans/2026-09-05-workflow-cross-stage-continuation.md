# Engineering Workflow 跨阶段续接修复

## Goal

让六个自有 Workflow Skill 在直接调用或从上一阶段返回时，始终显示下一步交接；让 `plan-only` 保持不写文件，同时显示明确的终点和可复制选择。外部 Skill 不修改，只接受当前调用的临时输出要求。

## Non-goals

- 不修改外部 Skill、宿主 UI 或具体工程项目。
- 不开启六个自有 Skill 的隐式触发。
- 不让 `check-only` 或 `plan-only` 获得 implementation 权限。
- 不自动 commit、push 或 publish。

## Current state

- 维护副本位于 `.agents/skills`，运行时副本位于 `/Users/mac2/.codex/skills`。
- 现有格式校验只能检查静态文案，无法检查多轮交接顺序。
- 已确认的 bad case 是 `plan-only` 输出方案后没有终点交接卡。

## Milestones

1. 为六个自有 Skill 增加跨轮次阶段协议和外部 Skill 临时调用边界。
2. 删除 `plan-only` 的冲突收尾规则，加入四项规划终点选择。
3. 增加多轮对话夹具和连续性校验脚本，保留旧 bad case 作为负向样例。
4. 更新 10 个中文真实场景和 3 个自动化回归场景。
5. 运行 Ruby 语法、格式、连续性、YAML、diff 和 runtime `cmp` 检查。

## Acceptance

- `task-brief → 确认` 的下一条回复是 Route 卡。
- `task-router → 确认路由 → plan-only` 的最后一条回复包含 `只保留方案`、`转成实施任务`、`继续聊聊`、`取消`，每个口令后都有 `> ` 说明。
- 外部 Skill 返回后，Workflow 重新整理正文并显示下一步，外部 Skill 文件没有变化。
- 10 个人工场景和 3 个自动化多轮回归通过。
- 六个维护副本与运行时副本逐文件一致。

## Stop conditions

如果宿主没有 callable native Plan、Review、Worktree 或 Goal，只输出准确的手动交接，不模拟这些能力。实现完成后运行真实检查，展示 `git status --short` 和 `git diff --stat`，等待用户明确要求再提交或发布。
