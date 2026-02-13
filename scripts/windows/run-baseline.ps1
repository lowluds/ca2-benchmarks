param(
    [string]$TargetPath = "",
    [string]$Arguments = "",
    [string]$WorkingDirectory = "",
    [string]$Scenario = "app-graphics3d-startup",
    [int]$Runs = 5,
    [int]$WarmupRuns = 1,
    [int]$RunDurationSec = 15,
    [int]$StartupIdleTimeoutSec = 8,
    [int]$SampleIntervalMs = 200
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..\\..")
$resultsDir = Join-Path $repoRoot "results\\baselines"

if (-not (Test-Path $resultsDir)) {
    New-Item -ItemType Directory -Force -Path $resultsDir | Out-Null
}

$checkScript = Join-Path $scriptRoot "check-prereqs.ps1"
Write-Host "Running runtime prerequisite checks..." -ForegroundColor Cyan
& $checkScript -Mode runtime
if ($LASTEXITCODE -ne 0) {
    Write-Host "Prerequisite check failed. Baseline run aborted." -ForegroundColor Red
    exit $LASTEXITCODE
}

if ([string]::IsNullOrWhiteSpace($TargetPath)) {
    Write-Host "No target executable was provided." -ForegroundColor Red
    Write-Host "Example:"
    Write-Host "powershell -ExecutionPolicy Bypass -File scripts/windows/run-baseline.ps1 -TargetPath C:\path\to\app.exe -Runs 5 -WarmupRuns 1 -RunDurationSec 20"
    exit 2
}

$measureScript = Join-Path $scriptRoot "measure-process.ps1"
& $measureScript `
    -TargetPath $TargetPath `
    -Arguments $Arguments `
    -WorkingDirectory $WorkingDirectory `
    -Scenario $Scenario `
    -Runs $Runs `
    -WarmupRuns $WarmupRuns `
    -RunDurationSec $RunDurationSec `
    -StartupIdleTimeoutSec $StartupIdleTimeoutSec `
    -SampleIntervalMs $SampleIntervalMs `
    -OutputDir $resultsDir

exit $LASTEXITCODE
