# Baseline Plan

## Objective
Create a repeatable baseline that allows all optimization changes to be measured against stable reference points.

## Phase 1 (Initial)
1. Environment readiness check
2. Baseline run scaffolding
3. Consistent output format (JSON + log)

## Phase 2 (First Real Metrics)
1. Startup time benchmark (implemented via `scripts/windows/measure-process.ps1`)
2. Time-boxed runtime benchmark (implemented)
3. Peak memory snapshot benchmark (implemented)
4. Optional FPS log parsing benchmark (implemented when app logs FPS)
5. Scene load benchmark (next)

## Rules
1. Keep test input and scene fixed for A/B comparisons.
2. Run each noisy benchmark at least 3 times.
3. Report median values for primary performance metrics.
4. Record host metadata (CPU, RAM, OS, GPU when available).

## Deliverables Per Baseline Iteration
1. Timestamped result files in `results/baselines/`
2. A short markdown baseline report from template
3. Known limitations and data confidence note

## Current Baseline Command (Windows)
`powershell -ExecutionPolicy Bypass -File scripts/windows/run-baseline.ps1 -TargetPath C:\path\to\app.exe -Runs 5 -WarmupRuns 1 -RunDurationSec 20`
