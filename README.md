# ca2-performance-lab

Performance engineering workspace for ca2 C++ applications and framework paths.

## Purpose
This repo exists to produce measurable, reproducible performance and stability improvements that can be upstreamed to ca2.

## First Actions
1. Run prerequisite check:
   - Runtime benchmark path: `powershell -ExecutionPolicy Bypass -File scripts/windows/check-prereqs.ps1 -Mode runtime`
   - Full build path: `powershell -ExecutionPolicy Bypass -File scripts/windows/check-prereqs.ps1 -Mode build`
2. Run first real baseline (replace with your built app path):
   - `powershell -ExecutionPolicy Bypass -File scripts/windows/run-baseline.ps1 -TargetPath C:\path\to\app.exe -Runs 5 -WarmupRuns 1 -RunDurationSec 20`
3. Pull latest public ca2 activity snapshot:
   - `powershell -ExecutionPolicy Bypass -File scripts/windows/fetch-ca2-recent.ps1`

## Structure
- `benchmarks/` benchmark scenarios and harnesses
- `scripts/windows/` automation scripts for local validation
- `reports/research/` generated snapshots of recent public ca2 work
- `reports/owner/` simple owner-facing change summaries
- `patches/upstream/` patch candidates prepared for upstream submission
- `results/baselines/` captured baseline outputs
- `reports/templates/` report templates for baseline and optimization tasks
- `docs/` build setup and benchmark plan

## Process Contract
- `PURPOSE.md` defines mission and goals.
- `AGENTS.md` defines anti-drift rules and required artifacts.

## Owner Handoff
- Start at `reports/owner/README.md` for the current patch set and superseded items.
- Use `reports/owner/owner-update-2026-02-13.md` for plain-language summary.
- Apply exact code changes from `patches/upstream/*.patch`.
