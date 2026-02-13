param(
    [string]$Org = "ca2",
    [int]$TopRepos = 5,
    [int]$CommitsPerRepo = 5,
    [string]$OutputDir = "reports/research"
)

$ErrorActionPreference = "Stop"

function Invoke-GitHubApi {
    param([string]$Url)
    try {
        return Invoke-RestMethod -Uri $Url -Headers @{ "User-Agent" = "ca2-benchmarks-script" }
    }
    catch {
        Write-Warning "GitHub API request failed: $Url"
        Write-Warning $_.Exception.Message
        return $null
    }
}

function Get-TopDirectory {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return "(unknown)"
    }
    if ($Path.Contains("/")) {
        return $Path.Split("/")[0]
    }
    return "(root)"
}

function FirstLine {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }
    return $Text.Split("`n")[0].Trim()
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$timestampUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss 'UTC'")
$dateStamp = (Get-Date).ToString("yyyy-MM-dd")

$reposUrl = "https://api.github.com/orgs/$Org/repos?per_page=100&type=public&sort=updated&direction=desc"
$repos = Invoke-GitHubApi -Url $reposUrl
if (-not $repos) {
    throw "Failed to fetch public repositories for org '$Org'."
}

$selectedRepos = $repos | Select-Object -First $TopRepos

$repoReports = @()
foreach ($repo in $selectedRepos) {
    $repoName = $repo.name
    $commitsUrl = "https://api.github.com/repos/$Org/$repoName/commits?per_page=$CommitsPerRepo"
    $commits = Invoke-GitHubApi -Url $commitsUrl
    if (-not $commits) {
        continue
    }

    $commitReports = @()
    $topDirFrequency = @{}
    foreach ($commit in $commits) {
        $sha = $commit.sha
        $detailsUrl = "https://api.github.com/repos/$Org/$repoName/commits/$sha"
        $details = Invoke-GitHubApi -Url $detailsUrl
        if (-not $details) {
            continue
        }

        $files = @()
        if ($details.files) {
            $files = $details.files | Select-Object -ExpandProperty filename
        }

        foreach ($file in $files) {
            $topDir = Get-TopDirectory -Path $file
            if (-not $topDirFrequency.ContainsKey($topDir)) {
                $topDirFrequency[$topDir] = 0
            }
            $topDirFrequency[$topDir]++
        }

        $commitReports += [pscustomobject]@{
            date  = $details.commit.author.date
            sha   = $sha.Substring(0, 7)
            title = FirstLine -Text $details.commit.message
            files = $files
        }
    }

    $hotPaths = $topDirFrequency.GetEnumerator() |
        Sort-Object -Property Value -Descending |
        Select-Object -First 6 |
        ForEach-Object { [pscustomobject]@{ path = $_.Key; touches = $_.Value } }

    $repoReports += [pscustomobject]@{
        name       = $repoName
        updated_at = $repo.updated_at
        pushed_at  = $repo.pushed_at
        size_kb    = $repo.size
        language   = $repo.language
        html_url   = $repo.html_url
        commits    = $commitReports
        hot_paths  = $hotPaths
    }
}

$continuumRepo = $repoReports | Where-Object { $_.name -eq "app-graphics3d" } | Select-Object -First 1
$continuumPathCommits = Invoke-GitHubApi -Url "https://api.github.com/repos/$Org/app-graphics3d/commits?path=continuum&per_page=8"

$continuumSummary = $null
if ($continuumPathCommits) {
    $continuumRecent = @()
    foreach ($c in ($continuumPathCommits | Select-Object -First 5)) {
        $continuumRecent += [pscustomobject]@{
            date  = $c.commit.author.date
            sha   = $c.sha.Substring(0, 7)
            title = FirstLine -Text $c.commit.message
            url   = $c.html_url
        }
    }
    $continuumSummary = [pscustomobject]@{
        repo                  = "app-graphics3d"
        continuum_path_commits = $continuumRecent
        continuum_repo_url    = "https://github.com/$Org/app-graphics3d/tree/main/continuum"
    }
}

$snapshot = [pscustomobject]@{
    generated_utc = $timestampUtc
    org           = $Org
    top_repos     = $repoReports
    continuum     = $continuumSummary
}

$jsonPath = Join-Path $OutputDir "ca2-recent-public-work-$dateStamp.json"
$mdPath = Join-Path $OutputDir "ca2-recent-public-work-$dateStamp.md"

$snapshot | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# ca2 Public Recent Work Snapshot")
$md.Add("")
$md.Add("- Generated: $timestampUtc")
$md.Add("- Organization: $Org")
$md.Add("- Repositories analyzed: $($repoReports.Count)")
$md.Add("")
$md.Add("## Top Repositories by Recent Update")
$md.Add("")
foreach ($r in $repoReports) {
    $md.Add("### $($r.name)")
    $md.Add("")
    $md.Add("- URL: $($r.html_url)")
    $md.Add("- Updated: $($r.updated_at)")
    $md.Add("- Pushed: $($r.pushed_at)")
    $md.Add("- Size (KB): $($r.size_kb)")
    $md.Add("- Language: $($r.language)")
    $md.Add("- Hot paths (recent commit file touches):")
    foreach ($h in $r.hot_paths) {
        $md.Add("  - $($h.path): $($h.touches)")
    }
    $md.Add("- Recent commits:")
    foreach ($c in $r.commits) {
        $md.Add("  - $($c.date) [$($c.sha)] $($c.title)")
    }
    $md.Add("")
}

$md.Add("## Continuum Focus (app-graphics3d/continuum)")
$md.Add("")
if ($continuumSummary) {
    $md.Add("- Continuum path: $($continuumSummary.continuum_repo_url)")
    $md.Add("- Recent commits touching continuum/:")
    foreach ($c in $continuumSummary.continuum_path_commits) {
        $md.Add("  - $($c.date) [$($c.sha)] $($c.title)")
    }
}
else {
    $md.Add("- No continuum path data available in this run.")
}
$md.Add("")
$md.Add("## Suggested Next Targets")
$md.Add("")
$md.Add("1. Build reproducible Windows baseline around app-graphics3d GPU paths (gpu_vulkan, draw2d_opengl) because these are active and likely performance-sensitive.")
$md.Add("2. Remove hardcoded SDK assumptions in public samples (for example fixed Vulkan SDK paths in continuum/CMakeLists.txt) to increase contributor success rate.")
$md.Add("3. Add a small benchmark scene and timing capture script so any optimization can be validated with before/after evidence.")

$md | Set-Content -Path $mdPath -Encoding UTF8

Write-Host "Wrote:"
Write-Host " - $jsonPath"
Write-Host " - $mdPath"
