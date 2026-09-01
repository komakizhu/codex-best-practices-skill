---
name: task-router
description: "Use only when the user explicitly invokes `$task-router` or an active `$engineering-workflow` invokes it internally. Do not activate from an ordinary repository request, discussion, explanation, brainstorming, hypothetical design, read-only understanding, or pasted code."
---

# Task Router

This is the lower-level router used internally by an active `$engineering-workflow` (and available for explicit direct use). It is a dormant, native-first intake router—not an engineering framework. It only gates authorization, classifies scope, and selects an existing Codex-native workflow. Once routed, the native workflow and the repository’s applicable `AGENTS.md` rules own execution and completion.

## Gate

Activate only for an explicit `$task-router` invocation or an internal call from an already active `$engineering-workflow`. A clear request to change, test, investigate, review, or otherwise perform a concrete action in the current repository does not activate this router by itself. If intent is ambiguous, stay in discussion mode. Read the root and applicable path-specific `AGENTS.md` files before repository work; they outrank this skill. Do not copy their policies into this skill or invent a replacement when one is absent.

An active `$engineering-workflow` invocation keeps this router available for its current engineering task. Urgency or implementation wording cannot implicitly bypass the selected route or its required native stages; only an explicit cancellation of the active Workflow can end that governing contract early.

When called internally by `$engineering-workflow`, this router requires a confirmed five-item Task Brief from the current task. If the brief has not been displayed and confirmed, return to the Task Brief stage without classifying, invoking native Plan, or modifying files. A user’s explicit direct `$task-router` invocation remains an independent lower-level entry and does not require the Workflow’s Brief gate.

For a routed task, choose exactly one authorization mode before classifying. A discussion-only message has no mode, size, route line, or native workflow.

- `implementation`: the user asked to modify the repository.
- `check-only`: the requested deliverable is a check, test, investigation, review, or diagnosis without a fix. “Do not modify” reinforces this boundary but does not turn a concrete check into planning. Findings do not grant write permission.
- `plan-only`: the requested deliverable is analysis, planning, or design only, or the user explicitly says to plan without implementation. A no-write instruction is binding, but by itself does not determine the mode.

If a user requests implementation while also forbidding writes, preserve the no-write boundary and explain the conflict; do not silently implement or relabel the request. Do not pause for routine approval during authorized implementation; pause only for a consequential product, architecture, API, compatibility, data-loss, security, irreversible/costly choice, or an explicit request to wait.

## Classify

Use uncertainty, impact, risk, reversibility, compatibility, migration/security concerns, milestones, and validation complexity—not file count or line count.

- **Small**: the method is clear, the change is narrow and low-risk, and verification is direct.
- **Medium**: the root cause or call path needs investigation, or the bounded work affects multiple modules, behavior, performance, concurrency, or ordinary refactoring.
- **Large**: the work changes persistence or formats, core architecture, public APIs/protocols, multiple subsystems, data/security boundaries, rollback strategy, or requires milestones, long-running work, or cross-session progress.

For `check-only`, classify the investigation itself: a directly reproducible failure in one area can be Small, while an unknown call path, multiple modules, environment interaction, or complex evidence trail is Medium or Large. The no-write boundary changes the mode, not the size.

Emit one concise line before routed work, in the user’s language where practical: `路由：Medium；模式：implementation。需要先定位根因，影响范围集中。` Do not narrate a second workflow state machine.

## Route

**Small** — Investigate only what is necessary. In `implementation`, make the smallest change; in `check-only` or `plan-only`, do not write. Run the project’s real targeted tests, lint, typecheck, build, or behavior checks; inspect the actual diff; then follow `AGENTS.md` for `git status` and the concise diff summary. Do not create an ExecPlan or Goal, and do not commit or publish automatically. Formal Review is normally unnecessary unless requested or the risk grows.

**Medium** — Investigate first. For `implementation`, complete the necessary read-only investigation, then invoke the host’s actual native Plan and wait for it to complete successfully before modifying any file. A hand-written outline or `update_plan` is not proof that native Plan mode was used. If native Plan is unavailable, say so, provide a ready `/plan` handoff, and stop before any write; do not silently replace it with this skill’s prose. For `check-only`, continue only with independent read-only checks that do not require the missing Plan, and report the limitation; for `plan-only`, return the handoff/plan and stop without writes. After a completed native plan, an authorized implementation may continue unless a consequential decision requires the user; `check-only` reports findings and stops, and `plan-only` reports the plan and stops. Run real verification for implementation. Use native Review or native Colleagues reviewer when there is meaningful logic, behavior, multi-module, concurrency, performance, or regression risk; do not force heavyweight Review for a low-risk Medium. Review never replaces tests; fix only confirmed findings and re-review when needed. If native Review is unavailable, provide the native handoff and do not self-review under another name.

When investigation has genuinely independent questions, prefer the host’s native Colleagues/sub-agent parallel workflow if it is available and permitted. Do not create parallel work merely for ceremony, and never claim it ran without an actual successful invocation.

**Large** — Use native Plan first. If Plan is unavailable, say so, provide a precise `/plan` handoff, and stop any implementation, ExecPlan persistence, Worktree, Goal, or Review; a check-only task may continue only with independent read-only checks that do not need the plan. For authorized implementation after a completed native plan, persist a living ExecPlan using the repository’s convention (default: `docs/exec-plans/YYYY-MM-DD-<task>.md`), then use native Worktree and native Goal when the current host actually exposes and permits them. Record goal/non-goals, current state, scope, constraints, risks, milestones and validation, compatibility/migration, rollback, progress, discoveries, decisions, acceptance criteria, and stop conditions; update progress as work changes. A Goal or Worktree must not be inferred or simulated: if the host requires an explicit user/UI action or no callable native entry exists, provide a precise handoff and stop. Never replace a Worktree with a copied directory or ordinary branch, or a Goal with an open-ended instruction. Verify every milestone, run final real checks, and use native Review against the actual base (normally `main`) before acceptance. In `check-only`, do not persist an ExecPlan or alter code; report the read-only findings. In `plan-only`, show the plan and stop without writing an ExecPlan, creating Worktree/Goal, implementing, or reviewing.

## Truthfulness and finish

Use the current host’s capability names and semantics, not stale assumptions. Never claim that Plan, Review, Colleagues, a sub-agent, Worktree, or Goal ran unless its invocation succeeded and its result is observable. Do not simulate any of them with custom prompts, a second Git workflow, hashes, baselines, frozen contracts, hard gates, or a private verification framework. Commit and publish only when the user explicitly requests the repository’s `AGENTS.md` command. After the routed task reaches its completion boundary, stop routing; a later ordinary conversation starts in discussion mode.

For boundary examples and manual acceptance checks, read [references/routing-cases.md](references/routing-cases.md) only when validating this router or resolving an ambiguous gate.
