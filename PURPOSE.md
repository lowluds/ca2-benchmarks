# ca2 Performance Lab Purpose

## Mission
Build a focused engineering workspace that improves the performance, stability, and build reliability of ca2 C++ applications through measurable, reproducible work.

## Why This Exists
- ca2 has high potential but uneven build/runtime behavior across targets.
- Optimization work is most valuable when it is benchmarked, repeatable, and easy to upstream.
- This lab exists to produce high-signal fixes the ca2 founder can review and merge with confidence.

## Primary Goals
1. Establish reliable baseline benchmarks for startup, scene load, frame time, and memory.
2. Identify and fix real bottlenecks in ca2-related C++ paths.
3. Keep all improvements evidence-based (before/after metrics, same test conditions).
4. Package improvements as clean, minimal, upstream-ready patches.

## Non-Goals
- Building a game engine replacement.
- Shipping feature-heavy products before performance basics are stable.
- Large refactors without benchmark proof.

## Success Criteria
- Benchmarks run with one command on Windows.
- Each optimization PR includes reproducible metrics.
- Regressions are detected early via repeat benchmark runs.
- Proposed patches are small, reviewable, and tied to a clear performance objective.

## Execution Strategy
1. Baseline: create benchmark harnesses and capture current numbers.
2. Diagnose: profile hot paths and rank by impact.
3. Optimize: apply smallest safe change for measurable gain.
4. Validate: rerun benchmark matrix and verify no major regressions.
5. Upstream: prepare patch notes, evidence, and PR-ready commits.

## Initial Focus
- Start with continuum-related workloads as the first benchmark target.
- Expand to broader ca2 subsystems after baseline automation is stable.

## Contribution Rule
No optimization is considered complete without:
- measured improvement,
- reproducible steps,
- and a clear rollback path.

