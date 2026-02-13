param(
    [Parameter(Mandatory = $true)]
    [string]$TargetPath,
    [string]$Arguments = "",
    [string]$WorkingDirectory = "",
    [string]$Scenario = "app-graphics3d-startup",
    [int]$Runs = 5,
    [int]$WarmupRuns = 1,
    [int]$RunDurationSec = 15,
    [int]$StartupIdleTimeoutSec = 8,
    [int]$SampleIntervalMs = 200,
    [string]$OutputDir = "",
    [string]$FpsRegex = "(?i)(fps|frame[\s_-]?rate)\s*[:=]\s*(?<fps>\d+(?:\.\d+)?)"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-Median {
    param([double[]]$Values)
    if (-not $Values -or $Values.Count -eq 0) {
        return $null
    }
    $sorted = $Values | Sort-Object
    $count = $sorted.Count
    if ($count % 2 -eq 1) {
        return [math]::Round([double]$sorted[[int]($count / 2)], 3)
    }
    $a = [double]$sorted[($count / 2) - 1]
    $b = [double]$sorted[$count / 2]
    return [math]::Round((($a + $b) / 2.0), 3)
}

function Get-MachineMetadata {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
    $memoryBytes = [double]$os.TotalVisibleMemorySize * 1024.0

    return [ordered]@{
        machine_name = $env:COMPUTERNAME
        user_name = $env:USERNAME
        os_caption = $os.Caption
        os_version = $os.Version
        cpu_name = $cpu.Name
        logical_cores = $cpu.NumberOfLogicalProcessors
        gpu_name = $gpu.Name
        ram_gb = [math]::Round(($memoryBytes / 1GB), 2)
    }
}

function Get-FpsSamplesFromFile {
    param(
        [string]$Path,
        [string]$Pattern
    )

    $fpsSamples = @()
    if (-not (Test-Path $Path)) {
        return $fpsSamples
    }

    $regex = [regex]::new($Pattern)
    $lines = Get-Content -Path $Path -ErrorAction SilentlyContinue
    foreach ($line in $lines) {
        $m = $regex.Match($line)
        if ($m.Success) {
            $value = $m.Groups["fps"].Value
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                $parsed = 0.0
                if ([double]::TryParse($value, [ref]$parsed)) {
                    $fpsSamples += $parsed
                }
            }
        }
    }

    return $fpsSamples
}

if (-not (Test-Path $TargetPath)) {
    throw "Target executable not found: $TargetPath"
}

if ([string]::IsNullOrWhiteSpace($WorkingDirectory)) {
    $WorkingDirectory = Split-Path -Parent (Resolve-Path $TargetPath)
}

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $repoRoot = Resolve-Path (Join-Path $scriptRoot "..\\..")
    $OutputDir = Join-Path $repoRoot "results\\baselines"
}

if ($Runs -lt 1) {
    throw "Runs must be >= 1."
}
if ($WarmupRuns -lt 0) {
    throw "WarmupRuns must be >= 0."
}
if ($WarmupRuns -ge $Runs) {
    throw "WarmupRuns must be less than Runs."
}
if ($RunDurationSec -lt 1) {
    throw "RunDurationSec must be >= 1."
}
if ($SampleIntervalMs -lt 50) {
    throw "SampleIntervalMs must be >= 50."
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$sessionDir = Join-Path $OutputDir ("{0}-{1}" -f $Scenario, $timestamp)
New-Item -ItemType Directory -Force -Path $sessionDir | Out-Null

$runResults = @()
Write-Host ("Running scenario '{0}' against '{1}'" -f $Scenario, $TargetPath) -ForegroundColor Cyan
Write-Host ("Runs: {0} (warmup: {1}, measured: {2})" -f $Runs, $WarmupRuns, ($Runs - $WarmupRuns)) -ForegroundColor Cyan

for ($i = 1; $i -le $Runs; $i++) {
    $isWarmup = $i -le $WarmupRuns
    $phase = if ($isWarmup) { "warmup" } else { "measured" }
    $stdoutPath = Join-Path $sessionDir ("run-{0:D2}.stdout.log" -f $i)
    $stderrPath = Join-Path $sessionDir ("run-{0:D2}.stderr.log" -f $i)

    Write-Host ("[{0}/{1}] {2} run starting..." -f $i, $Runs, $phase) -ForegroundColor Yellow

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $startupSw = [System.Diagnostics.Stopwatch]::StartNew()
    $killed = $false
    $startupMs = $null
    $maxWorkingSetBytes = 0.0
    $processIdValue = -1

    try {
        $startArgs = @{
            FilePath = $TargetPath
            WorkingDirectory = $WorkingDirectory
            PassThru = $true
            RedirectStandardOutput = $stdoutPath
            RedirectStandardError = $stderrPath
        }
        if (-not [string]::IsNullOrWhiteSpace($Arguments)) {
            $startArgs["ArgumentList"] = $Arguments
        }
        $p = Start-Process @startArgs

        $processIdValue = $p.Id

        try {
            $idleOk = $p.WaitForInputIdle($StartupIdleTimeoutSec * 1000)
            if ($idleOk) {
                $startupMs = [math]::Round($startupSw.Elapsed.TotalMilliseconds, 3)
            }
        }
        catch {
            $startupMs = $null
        }

        while (-not $p.HasExited) {
            $p.Refresh()
            $currentWs = [double]$p.WorkingSet64
            if ($currentWs -gt $maxWorkingSetBytes) {
                $maxWorkingSetBytes = $currentWs
            }

            if ($stopwatch.Elapsed.TotalSeconds -ge $RunDurationSec) {
                Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
                $killed = $true
                break
            }
            Start-Sleep -Milliseconds $SampleIntervalMs
        }

        $null = $p.WaitForExit(5000)
        $stopwatch.Stop()
        $p.Refresh()

        $peakWorkingSetFromProcess = 0.0
        try {
            $peakWorkingSetFromProcess = [double]$p.PeakWorkingSet64
        }
        catch {
            $peakWorkingSetFromProcess = 0.0
        }
        if ($peakWorkingSetFromProcess -gt $maxWorkingSetBytes) {
            $maxWorkingSetBytes = $peakWorkingSetFromProcess
        }

        $finalWorkingSet = 0.0
        try {
            $finalWorkingSet = [double]$p.WorkingSet64
        }
        catch {
            $finalWorkingSet = 0.0
        }
        if ($finalWorkingSet -gt $maxWorkingSetBytes) {
            $maxWorkingSetBytes = $finalWorkingSet
        }

        $cpuMs = $null
        try {
            $cpuMs = [math]::Round([double]$p.TotalProcessorTime.TotalMilliseconds, 3)
        }
        catch {
            $cpuMs = $null
        }

        $exitCode = $null
        try {
            if ($p.HasExited) {
                $exitCode = [int]$p.ExitCode
            }
        }
        catch {
            $exitCode = $null
        }

        $fpsSamples = @()
        $fpsSamples += Get-FpsSamplesFromFile -Path $stdoutPath -Pattern $FpsRegex
        $fpsSamples += Get-FpsSamplesFromFile -Path $stderrPath -Pattern $FpsRegex
        $fpsMedian = if ($fpsSamples.Count -gt 0) { Get-Median -Values $fpsSamples } else { $null }

        $runResults += [pscustomobject]@{
            run_index = $i
            phase = $phase
            pid = $processIdValue
            killed = $killed
            exit_code = $exitCode
            startup_ms = $startupMs
            runtime_ms = [math]::Round($stopwatch.Elapsed.TotalMilliseconds, 3)
            peak_working_set_mb = [math]::Round(($maxWorkingSetBytes / 1MB), 3)
            cpu_total_ms = $cpuMs
            fps_median = $fpsMedian
            fps_samples = $fpsSamples.Count
            stdout_log = $stdoutPath
            stderr_log = $stderrPath
            error = $null
        }
    }
    catch {
        $stopwatch.Stop()
        $runResults += [pscustomobject]@{
            run_index = $i
            phase = $phase
            pid = $processIdValue
            killed = $killed
            exit_code = $null
            startup_ms = $null
            runtime_ms = [math]::Round($stopwatch.Elapsed.TotalMilliseconds, 3)
            peak_working_set_mb = $null
            cpu_total_ms = $null
            fps_median = $null
            fps_samples = 0
            stdout_log = $stdoutPath
            stderr_log = $stderrPath
            error = $_.Exception.Message
        }
    }
}

$measured = $runResults | Where-Object { $_.phase -eq "measured" }

$startupValues = @($measured | Where-Object { $null -ne $_.startup_ms } | ForEach-Object { [double]$_.startup_ms })
$runtimeValues = @($measured | Where-Object { $null -ne $_.runtime_ms } | ForEach-Object { [double]$_.runtime_ms })
$memoryValues = @($measured | Where-Object { $null -ne $_.peak_working_set_mb } | ForEach-Object { [double]$_.peak_working_set_mb })
$cpuValues = @($measured | Where-Object { $null -ne $_.cpu_total_ms } | ForEach-Object { [double]$_.cpu_total_ms })
$fpsValues = @($measured | Where-Object { $null -ne $_.fps_median } | ForEach-Object { [double]$_.fps_median })

$failedRuns = @($measured | Where-Object { $_.error -or (($null -ne $_.exit_code) -and $_.exit_code -ne 0 -and -not $_.killed) })
$killedRuns = @($measured | Where-Object { $_.killed })

$summary = [ordered]@{
    startup_ms_median = Get-Median -Values $startupValues
    runtime_ms_median = Get-Median -Values $runtimeValues
    peak_working_set_mb_median = Get-Median -Values $memoryValues
    cpu_total_ms_median = Get-Median -Values $cpuValues
    fps_median = Get-Median -Values $fpsValues
    measured_runs = $measured.Count
    failed_runs = $failedRuns.Count
    killed_runs = $killedRuns.Count
}

$payload = [ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    scenario = $Scenario
    target = [ordered]@{
        path = $TargetPath
        arguments = $Arguments
        working_directory = $WorkingDirectory
    }
    run_config = [ordered]@{
        total_runs = $Runs
        warmup_runs = $WarmupRuns
        measured_runs = $Runs - $WarmupRuns
        run_duration_sec = $RunDurationSec
        startup_idle_timeout_sec = $StartupIdleTimeoutSec
        sample_interval_ms = $SampleIntervalMs
    }
    host = Get-MachineMetadata
    summary = $summary
    runs = $runResults
}

$jsonPath = Join-Path $sessionDir "baseline-result.json"
$mdPath = Join-Path $sessionDir "baseline-result.md"

$payload | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

$mdLines = @()
$mdLines += "# Baseline Result"
$mdLines += ""
$mdLines += ("- Scenario: {0}" -f $Scenario)
$mdLines += ("- Target: {0}" -f $TargetPath)
$mdLines += ("- Timestamp (UTC): {0}" -f $payload.timestamp_utc)
$mdLines += ("- Measured runs: {0}" -f $summary.measured_runs)
$mdLines += ("- Failed runs: {0}" -f $summary.failed_runs)
$mdLines += ("- Killed runs (time-boxed): {0}" -f $summary.killed_runs)
$mdLines += ""
$mdLines += "## Median Metrics"
$mdLines += ""
$mdLines += ("- startup_ms: {0}" -f $summary.startup_ms_median)
$mdLines += ("- runtime_ms: {0}" -f $summary.runtime_ms_median)
$mdLines += ("- peak_working_set_mb: {0}" -f $summary.peak_working_set_mb_median)
$mdLines += ("- cpu_total_ms: {0}" -f $summary.cpu_total_ms_median)
$mdLines += ("- fps_median (from logs): {0}" -f $summary.fps_median)
$mdLines += ""
$mdLines += "## Artifacts"
$mdLines += ""
$mdLines += ("- JSON: {0}" -f $jsonPath)
$mdLines += ("- Logs folder: {0}" -f $sessionDir)

$mdLines | Set-Content -Path $mdPath -Encoding UTF8

Write-Host ""
Write-Host "Benchmark run complete." -ForegroundColor Green
Write-Host ("JSON: {0}" -f $jsonPath)
Write-Host ("MD:   {0}" -f $mdPath)

exit 0
