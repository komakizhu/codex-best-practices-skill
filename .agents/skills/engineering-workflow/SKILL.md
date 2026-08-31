---
name: engineering-workflow
description: "Use when the user explicitly invokes `$engineering-workflow` or clearly requests a concrete repository change or targeted engineering check. Do not use for ordinary discussion, explanation, brainstorming, hypothetical design, read-only code understanding, or pasted code without an action request."
---

# Engineering Workflow

This is a thin, dormant, native-first entry point for repository engineering work. It coordinates the repository’s task-definition and routing skills, then yields execution to the host’s native Codex capabilities and the repository’s `AGENTS.md`.

## Boundary

Activate only for an explicit `$engineering-workflow` invocation or a clear request to change, test, investigate, review, or otherwise perform a concrete action in the current repository. Do not activate for ordinary conversation, explanations, brainstorming, architecture discussion, hypothetical questions, read-only understanding, or pasted code without execution intent.

Keep the user’s authorization boundary intact. The workflow has exactly one mode: `implementation`, `check-only`, or `plan-only`. Never turn a check into a fix, or a plan into implementation.

## Composition

1. Use `$task-brief` when the request is still scattered or ambiguous. If the current conversation already gives enough information, form the brief internally and do not force a separate intake step.
2. Use `$task-router` to classify authorization and scope (`Small`, `Medium`, or `Large`). Follow its native-first routing rules.
3. Consider `$option-explorer` only when there are at least two materially different viable paths, no clear winner, and a costly wrong choice. Ask whether the user wants the extra native parallel exploration before using it.
4. Execute with the lightest suitable native Plan, Review, Goal, Worktree, Colleagues, and project verification. Do not recreate any of them inside a Skill.
5. After completed engineering work, use `$repo-retrospective` for a lightweight, evidence-based repository-environment review.
6. Follow `AGENTS.md` for real verification, `git status`, concise diff summary, and stopping. Never commit or publish automatically.

This Skill does not implement planning, review, goals, worktrees, colleague orchestration, or a test framework. It only connects the four named skills and preserves their boundaries.
