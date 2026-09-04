# Engineering Workflow 全阶段续接

## Goal

让用户从任意公开中间 Skill 开始，都能沿着完整 engineering-workflow 继续到正确的结束点；每一步都能看懂当前结论、下一步、执行者、可复制口令和权限边界。

## Non-goals

- 不修改具体工程项目代码或宿主 UI。
- 不改变 RCA、Route、Option、Plan、implementation、Review、Worktree 或 Goal 的权限含义。
- 不模拟 native Plan、Review、Worktree、Goal 或 Colleagues。
- 不自动提交、推送或发布。

## Current state and RCA

此前的格式改造已统一首行结论、字段分行和口令段落，但 RCA 发现阶段规则仍允许断链：`check-only` / `plan-only` 可以报告后停止，且公开中间 Skill 被定义成独立入口。格式校验可以通过，却不能发现“没有下一步”的语义缺口。

## Scope and decisions

- 六个公开 Skill 共用阶段入口与阶段完成交接契约。
- 公开中间 Skill 的直接调用默认进入完整 Workflow 的对应阶段；明确的 `只分析`、`只保留结论`、`只做计划` 和 `取消` 仍然是终止边界。
- `先聊一聊` 只用于 Brief；Brief 之后的等待卡统一使用 `继续聊聊`。
- `check-only` 和 `plan-only` 必须给出下一步或明确终点，但不会获得 implementation 权限。
- native Plan 结果出现或宿主 Implement/return-to-execution 后才可执行；不再要求“Plan 已完成”。
- 不使用 Worktree 或 Goal；维护副本通过 `cmp` 与运行时副本同步。

## Milestones and validation

1. 更新 `engineering-workflow`、`task-brief`、`task-router`、`rca-analyze`、`option-explorer`、`repo-retrospective` 的入口和交接规则。
2. 更新 Workflow context、路由验收案例和连续性校验器。
3. 运行 Ruby 语法检查、工作流格式校验、`git diff --check`，并同步六个运行时副本。
4. 逐一检查直接 Skill 入口、Route → RCA → Brief → Plan 链路、Option 分支、Plan 执行授权、完成报告和 `继续聊聊`/`先聊一聊` 边界。
5. 检查实际 diff、`git status --short` 和 `git diff --stat`；若宿主提供 native Review，再对比 `main`。

## Compatibility, rollback, and stop conditions

保留现有口令和授权边界，新增的是阶段交接要求。若验证失败，停止在当前里程碑，修正维护副本后再同步运行时副本。回滚时只恢复本任务新增或修改的文件，并重新运行格式校验和 `cmp`；不触碰工作区中的无关修改。

## Progress

- [x] 完成跨 Skill RCA，确认断链规则来源。
- [x] 更新公共阶段入口和续接规则。
- [x] 增加中间 Skill 端到端验收案例。
- [x] 扩展连续性校验器并通过静态检查。
- [x] 同步运行时副本并完成最终验证。
