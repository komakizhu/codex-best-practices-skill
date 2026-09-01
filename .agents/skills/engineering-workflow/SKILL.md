---
name: engineering-workflow
description: "Use only when the user explicitly invokes `$engineering-workflow` to summarize and route a repository engineering task. Do not activate from an ordinary repository request, discussion, explanation, brainstorming, hypothetical design, read-only understanding, or pasted code."
---

# Engineering Workflow

This is a thin, dormant, native-first entry point for repository engineering work. It is activated only by an explicit user invocation, coordinates the repository’s task-definition and routing skills, then yields execution to the host’s native Codex capabilities and the repository’s `AGENTS.md`.

## Boundary

Activate only when the user explicitly invokes `$engineering-workflow`. A clear request to change, test, investigate, review, or otherwise perform a concrete action in the current repository does not activate this Skill by itself. Do not activate for ordinary conversation, explanations, brainstorming, architecture discussion, hypothetical questions, read-only understanding, or pasted code without execution intent.

Once explicitly activated, keep this workflow active for the current engineering task through completion. Interpret urgency and implementation wording—such as “直接修”“马上做”“不要再问” or “跳过计划”—as task intent or authorization, never as permission to skip a required stage. End the active workflow early only when the user explicitly asks to exit, cancel, or stop using `$engineering-workflow`; do not treat an implicit change of tone as cancellation. The invocation itself does not grant write permission: the request still determines `implementation`, `check-only`, or `plan-only`.

Before routing, always inspect the current conversation and repository context through `$task-brief` and display a five-item brief: `目标`, `当前上下文/证据`, `约束与授权`, `范围/非目标`, and `验收标准/待确认项`. Do not silently form or skip this brief when the context is already clear. Stop after displaying it and wait for a subsequent user response: confirmation proceeds, a correction regenerates the complete brief and waits again, and an explicit cancellation ends the workflow. Do not invoke `$task-router`, native Plan, or modify files before confirmation. A post-brief response such as “确认”“按这个做” or “直接修” may confirm the brief and select `implementation`, but it cannot bypass any later required native stage.

Keep the user’s authorization boundary intact. The workflow has exactly one mode: `implementation`, `check-only`, or `plan-only`. Never turn a check into a fix, or a plan into implementation.

## Composition

1. Always use `$task-brief` after activation to produce and display the five-item brief, then wait for confirmation, correction, or cancellation before continuing.
2. After confirmation, use `$task-router` to classify authorization and scope (`Small`, `Medium`, or `Large`). Follow its native-first routing rules.
3. Consider `$option-explorer` only when there are at least two materially different viable paths, no clear winner, and a costly wrong choice. Ask whether the user wants the extra native parallel exploration before using it.
4. Execute with the native stages required by the route, followed by the lightest suitable native Review, Goal, Worktree, Colleagues, and project verification. Small implementation may proceed directly; Medium and Large implementation must complete the host’s actual native Plan before the first file modification. Do not recreate any of these capabilities inside a Skill.
5. After completed engineering work, use `$repo-retrospective` for a lightweight, evidence-based repository-environment review.
6. Follow `AGENTS.md` for real verification, `git status`, concise diff summary, and stopping. Never commit or publish automatically.

This Skill does not implement planning, review, goals, worktrees, colleague orchestration, or a test framework. It only connects the four named skills and preserves their boundaries.
