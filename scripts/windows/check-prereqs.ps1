param(
    [ValidateSet("build", "runtime")]
    [string]$Mode = "build"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-CommandExists {
    param([Parameter(Mandatory = $true)][string]$Name)
    try {
        $null = Get-Command $Name -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

Write-Host "== ca2-performance-lab prerequisite check ==" -ForegroundColor Cyan

$checks = if ($Mode -eq "runtime") {
    @(
        @{ Name = "git"; Required = $true; Hint = "Install Git for Windows: https://git-scm.com/download/win" }
        @{ Name = "powershell"; Required = $true; Hint = "Use Windows PowerShell or PowerShell 7." }
        @{ Name = "cmake"; Required = $false; Hint = "Recommended for future source builds: https://cmake.org/download/" }
        @{ Name = "cl"; Required = $false; Hint = "Recommended for future source builds: Visual Studio Build Tools + Desktop C++." }
    )
}
else {
    @(
        @{ Name = "git"; Required = $true; Hint = "Install Git for Windows: https://git-scm.com/download/win" }
        @{ Name = "cmake"; Required = $true; Hint = "Install CMake and add to PATH: https://cmake.org/download/" }
        @{ Name = "cl"; Required = $true; Hint = "Install Visual Studio Build Tools + Desktop development with C++; run from Developer PowerShell." }
        @{ Name = "powershell"; Required = $true; Hint = "Use Windows PowerShell or PowerShell 7." }
    )
}

$missingRequired = @()
$missingRecommended = @()

foreach ($check in $checks) {
    $exists = Test-CommandExists -Name $check.Name
    $status = if ($exists) { "OK" } else { "MISSING" }
    $color = if ($exists) { "Green" } else { "Yellow" }
    Write-Host ("[{0}] {1}" -f $status, $check.Name) -ForegroundColor $color

    if (-not $exists -and $check.Required) {
        $missingRequired += $check
    }
    elseif (-not $exists -and -not $check.Required) {
        $missingRecommended += $check
    }
}

# Vulkan-related checks are optional for non-Vulkan benchmark paths.
$vulkanSdk = $env:VULKAN_SDK
$hasVulkanSdk = -not [string]::IsNullOrWhiteSpace($vulkanSdk) -and (Test-Path $vulkanSdk)
$hasGlslang = Test-CommandExists -Name "glslangValidator"

Write-Host ""
Write-Host "Optional (needed for continuum Vulkan/shader paths):" -ForegroundColor Cyan
Write-Host ("[{0}] VULKAN_SDK env var" -f ($(if ($hasVulkanSdk) { "OK" } else { "MISSING" }))) -ForegroundColor $(if ($hasVulkanSdk) { "Green" } else { "Yellow" })
Write-Host ("[{0}] glslangValidator" -f ($(if ($hasGlslang) { "OK" } else { "MISSING" }))) -ForegroundColor $(if ($hasGlslang) { "Green" } else { "Yellow" })

if (-not $hasGlslang -and $hasVulkanSdk) {
    $candidate = Join-Path $vulkanSdk "Bin\\glslangValidator.exe"
    if (Test-Path $candidate) {
        Write-Host ("[INFO] Found glslangValidator at {0}. Add this folder to PATH for convenience." -f (Split-Path $candidate -Parent)) -ForegroundColor DarkCyan
    }
}

Write-Host ""
if ($missingRequired.Count -gt 0) {
    Write-Host "Missing required prerequisites:" -ForegroundColor Red
    foreach ($item in $missingRequired) {
        Write-Host ("- {0}: {1}" -f $item.Name, $item.Hint) -ForegroundColor Red
    }
    exit 1
}

Write-Host "Required prerequisites are available." -ForegroundColor Green
if ($missingRecommended.Count -gt 0) {
    Write-Host "Missing recommended tools:" -ForegroundColor Yellow
    foreach ($item in $missingRecommended) {
        Write-Host ("- {0}: {1}" -f $item.Name, $item.Hint) -ForegroundColor Yellow
    }
}
if (-not $hasVulkanSdk -or -not $hasGlslang) {
    Write-Host "Vulkan/shader tooling is optional for now but required for full continuum Vulkan workflows." -ForegroundColor Yellow
}

exit 0
