# Repository Agent Instructions

## Workflow boundary

`$engineering-workflow` is the repository’s engineering entry point. It is dormant by default: activate it only when the user explicitly invokes it or clearly asks for a concrete repository change or targeted engineering check. Ordinary conversation, explanation, brainstorming, architecture discussion, hypothetical design, read-only code understanding, and pasted code without an action request remain outside the engineering workflow.

Use the native Codex capabilities already provided by the host for Plan, Review, Goal, Worktree, Colleagues, and verification. Skills may organize and route those capabilities, but must not reimplement or simulate them. Never claim that a native capability ran unless the host actually reports a successful invocation.

`$task-router` remains the lower-level authorization and scope router. It is not the total workflow entry point. Preserve the user’s mode exactly: `implementation`, `check-only`, or `plan-only`; inspection and analysis do not grant permission to modify files.

## Git and completion

After engineering work, run the project’s relevant real checks, inspect the actual diff, show `git status` and a concise diff summary, then stop. Do not commit or publish unless the user explicitly requests it. Preserve unrelated user changes and do not use destructive commands against broad or unresolved paths.

For large work, follow the repository’s ExecPlan convention when one exists; otherwise use `docs/exec-plans/YYYY-MM-DD-<task>.md` only when the routed workflow requires a persisted plan.
