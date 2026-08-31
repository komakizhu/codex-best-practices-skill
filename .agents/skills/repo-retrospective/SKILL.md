---
name: repo-retrospective
description: "Use when an engineering task has completed and you need to check whether the repository environment caused repeatable agent friction or needs a small durable improvement."
---

# Repository Retrospective

Perform a lightweight, evidence-based review of the repository environment after completed engineering work. The subject is agent-friendliness, not a retelling of the task or a second code review.

Look for concrete friction such as repeatedly guessing test commands, unclear startup instructions, unstable environment-variable entry points, local/CI command drift, recurring special build flags, stale `AGENTS.md` rules, or a repeated manual reminder that could become a test or script.

Default to no changes. Persist an improvement only when all are true:

1. this task caused real rework, an error, or repeated investigation;
2. the friction is likely to recur; and
3. a short, stable change would materially reduce it.

Choose the narrowest durable home: machine-verifiable behavior belongs in a test, script, CI check, or stable command; lasting project rules belong in `AGENTS.md`; workflow-specific guidance belongs in a Skill; architectural background belongs in `docs`; and task-only state belongs in an ExecPlan. Do not save one-off paths, unverified guesses, temporary debugging notes, or routine task summaries.

Keep the user’s authorization mode. A `check-only` or `plan-only` task must not acquire write permission through the retrospective. For implementation, make only an in-scope, low-risk durable improvement when the evidence and destination are clear; otherwise report the candidate without changing files. Record the evidence, chosen destination, and whether anything changed.
