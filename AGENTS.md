# Repository Agent Instructions

## Git and completion

After engineering work, run the project’s relevant real checks, inspect the actual diff, show `git status` and a concise diff summary, then stop. Do not commit or publish unless the user explicitly requests it. Preserve unrelated user changes and do not use destructive commands against broad or unresolved paths.

For large work, follow the repository’s ExecPlan convention when one exists; otherwise use `docs/exec-plans/YYYY-MM-DD-<task>.md` only when the routed workflow requires a persisted plan.

For workflow changes, treat symptom-only Bug reports as read-only RCA, explicit diagnosis requests as `check-only`, and do not write a Bug fix until the root cause is established. Explicit repair requests still carry this pre-write RCA requirement.
