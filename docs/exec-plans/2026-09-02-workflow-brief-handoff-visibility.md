# Workflow brief / handoff 可视化契约

## Goal

让 Workflow 的 brief、路由、RCA、Option 和收尾卡片先呈现一句可扫读的核心结论，再以普通文字分层展示详情，并把回复口令逐项列出。

## Non-goals

- 不改变路由分类、授权模式、RCA 前置条件、Option 触发条件或 Plan 确认门槛。
- 不引入渲染框架、业务代码、数据迁移或新的调用口令。
- 不提交或发布。

## Current state and RCA

六个 Skill 的输出示例都使用 `text` 代码块和单行字段。handoff 契约只要求四个语义字段，没有规定视觉层级；回复口令使用分号串联。只读基线检查命中 47 个可检测问题，维护副本与 `/Users/mac2/.codex/skills` 的运行时副本一致。

## Scope and decisions

- `.agents/skills` 是版本化维护源；六个对应的运行时 `SKILL.md` 必须保持字节一致。
- 保留 `已完成`、`下一步`、`需要你确认`、`怎么回复` 以及现有确认口令；只改变展示结构。
- Handoff 首行使用 `**结论：...**`；Task Brief 首项使用 `**目标：...**`，以保持五项结构。
- 使用一个无外部依赖的 Ruby 静态检查脚本，验证 Markdown 模板结构。
- 不使用 Worktree 或 Goal；执行范围有限且运行时副本需要在当前宿主直接验证。

## Milestones and validation

1. 更新父级视觉契约及六个 Skill 的输出模板；运行静态检查确认旧格式仍只剩待同步/模板问题。
2. 更新路由验收案例和上下文文档；运行 Ruby 语法检查及静态格式检查。
3. 将六个维护副本同步到 `/Users/mac2/.codex/skills`；逐一运行 `cmp`。
4. 执行最终检查：静态验证、`git diff --check`、`git status --short`、`git diff --stat`；如宿主提供 native Review，再对比 `main`。

## Compatibility, rollback, and stop conditions

现有字段名、口令和流程边界保持兼容。若验证失败，停止在当前里程碑并修正模板，不同步不完整内容。回滚时恢复本次修改的维护文件和脚本至当前 `HEAD`，再从维护副本恢复运行时副本并重新运行 `cmp`。

## Acceptance

- 所有目标输出示例首行是加粗的单句结论或目标。
- 详情不与字段标签挤在同一行；路由、模式、类型等元信息分行。
- 回复口令每项独立成列表项，不使用分号串联多个动作。
- Task Brief 仍有且只有五项，确认列表归属于第五项。
- 静态格式脚本通过，维护副本与运行时副本一致，工作区 diff 仅包含本任务范围。

## Progress

- [x] 完成 RCA 与计划确认。
- [x] 写入静态检查脚本，并在旧模板上验证红灯。
- [x] 更新 Skill 模板和配套文档。
- [x] 运行绿灯验证并同步运行时副本。
