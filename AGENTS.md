# AGENTS Operating Contract

This file is the authoritative operating contract for any agent working in this workspace.
If instructions conflict, follow this file unless the user gives a direct override.

## Project Identity
- Project: `ca2-performance-lab`
- Domain: C++ performance engineering for ca2-related applications and framework paths
- Primary outcome: measurable optimization work that can be shared with the ca2 founder

## North Star
Improve ca2 performance and reliability with reproducible evidence, not assumptions.

## Hard Scope
Agents must stay within:
1. Benchmarking and profiling infrastructure.
2. Performance and stability fixes in relevant C++ code paths.
3. Build reliability improvements that unblock measurement and delivery.
4. Upstream-ready patch preparation with clear evidence.

## Out of Scope (Unless User Explicitly Requests)
1. Unrelated product features.
2. Cosmetic refactors without performance value.
3. Broad architecture rewrites without benchmark justification.
4. Work that cannot be measured or verified.

## Priority Order
When choosing what to do next, use this order:
1. Unblock build and benchmark execution.
2. Produce baseline measurements.
3. Fix the highest-impact bottleneck.
4. Reduce regression risk with repeatable checks.
5. Improve developer ergonomics only after 1-4 are stable.

## Anti-Drift Rules
Agents must:
1. Tie every change to a stated performance or reliability objective.
2. Declare expected metric impact before editing code.
3. Capture before/after numbers for any optimization claim.
4. Stop and escalate if the task drifts away from project goals.
5. Prefer small, reversible changes over large speculative changes.

Agents must not:
1. Continue a change that has no measurable value.
2. Hide regressions or omit failed measurements.
3. Merge unrelated edits into the same patch.

## Standard Work Loop
For each task, execute in this order:
1. Define objective and target metric.
2. Reproduce baseline.
3. Implement minimal change.
4. Re-measure under same conditions.
5. Record results and risk notes.
6. Prepare clean commit/patch summary.

## Required Artifacts Per Optimization Task
1. Problem statement (1-3 lines).
2. Exact reproduction steps.
3. Baseline metrics.
4. Change summary.
5. Post-change metrics.
6. Regression check notes.
7. Next-step recommendation.

## Measurement Quality Bar
1. Same machine and similar load state for A/B runs.
2. Same input/scene/test duration unless intentionally changed.
3. At least 3 runs for noisy metrics; report median where possible.
4. Clearly mark incomplete or uncertain data.

## Definition of Done
A task is done only when:
1. The stated objective is met or disproven with evidence.
2. Changes build in the intended target path.
3. Measurements are documented.
4. Risks and follow-ups are explicitly listed.

## Communication Contract
Agents should communicate:
1. What is being changed.
2. Why it matters for performance/reliability.
3. What evidence supports the result.
4. What remains unknown.

No motivational filler. Keep communication precise and technical.

## Branch and Commit Hygiene
1. One logical objective per commit.
2. Commit message format:
   - `perf: ...` for performance improvements
   - `build: ...` for build/reliability fixes
   - `bench: ...` for benchmark tooling/data
   - `docs: ...` for process/reporting updates
3. Do not bundle formatting-only churn with functional changes.

## Escalation Conditions
Stop and ask for user direction if:
1. Baseline cannot be reproduced.
2. A change causes >5% regression in a protected metric.
3. Toolchain/environment assumptions are invalid.
4. Required source/dependency access is missing.

## First Milestone Checklist
1. Benchmark harness skeleton exists.
2. Windows build path is documented and runnable.
3. First baseline report is captured.
4. First optimization patch with before/after evidence is prepared.

