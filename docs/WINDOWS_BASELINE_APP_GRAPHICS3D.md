# Windows Baseline: app-graphics3d

## Goal
Capture reproducible baseline metrics for a built `app-graphics3d` executable:
1. Startup time (ms)
2. Runtime duration in a fixed time window (ms)
3. Peak working set memory (MB)
4. CPU total time (ms)
5. Optional FPS median (if FPS text is present in logs)

## Prerequisite Check
Run runtime-only checks:

`powershell -ExecutionPolicy Bypass -File scripts/windows/check-prereqs.ps1 -Mode runtime`

## Baseline Command
Replace the executable path with your local build output:

`powershell -ExecutionPolicy Bypass -File scripts/windows/run-baseline.ps1 -TargetPath C:\path\to\continuum.exe -Scenario app-graphics3d-startup -Runs 5 -WarmupRuns 1 -RunDurationSec 20`

## Artifacts
Each run creates a timestamped folder under:

`results/baselines/<scenario>-<timestamp>/`

Artifacts include:
1. `baseline-result.json` full per-run metrics and host metadata
2. `baseline-result.md` quick summary
3. `run-XX.stdout.log` and `run-XX.stderr.log` for each run

## Notes
1. Keep machine load stable during A/B tests.
2. Use the same executable, arguments, and run duration for before/after comparisons.
3. For noisy metrics, keep at least 5 total runs with 1 warmup run.
