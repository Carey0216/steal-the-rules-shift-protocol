param(
    [Parameter(Mandatory)][ValidatePattern('^v\d+\.\d+\.\d+$')][string] $Tag,
    [Parameter(Mandatory)][string] $Commit,
    [Parameter(Mandatory)][string] $BuildDir,
    [Parameter(Mandatory)][string] $Notes,
    [switch] $Latest
)

$ErrorActionPreference = 'Stop'
$env:GCM_INTERACTIVE = 'never'
$env:GIT_TERMINAL_PROMPT = '0'
$remote = 'https://github.com/Carey0216/steal-the-rules-shift-protocol.git'
$api = 'https://api.github.com/repos/Carey0216/steal-the-rules-shift-protocol'

function Invoke-RepoGit {
    & git -c http.proxy= -c http.https://github.com.proxy= @args
    if ($LASTEXITCODE -ne 0) { throw 'Git operation failed.' }
}

$origin = (Invoke-RepoGit remote get-url origin).Trim()
if ($origin -ne $remote) { throw 'Unexpected GitHub repository.' }
$sha = (Invoke-RepoGit rev-parse --verify "$Commit^{commit}").Trim()
$settings = (Invoke-RepoGit show "${sha}:project.godot") -join "`n"
$projectVersion = 'config/version="' + $Tag.Substring(1) + '"'
if (-not ($settings -split "`r?`n").Contains($projectVersion)) { throw 'Tag must match the version in project.godot.' }
$builds = @('shift-protocol-windows-x64.zip', 'shift-protocol-web.zip')
$files = @($builds | ForEach-Object { Get-Item -LiteralPath (Join-Path $BuildDir $_) })

$query = @('protocol=https', 'host=github.com', '', '') -join "`n"
$response = $query | git credential fill 2>$null
$credential = $response | Where-Object { $_ -like 'password=*' } | Select-Object -First 1
if (-not $credential) { throw 'Sign in to GitHub before publishing a release.' }
$headers = @{
    Authorization = 'Bearer ' + $credential.Substring(9)
    'User-Agent' = 'Shift-Protocol'
    Accept = 'application/vnd.github+json'
}
$actor = Invoke-RestMethod 'https://api.github.com/user' -Headers $headers
if ($actor.login -ne 'Carey0216') { throw 'The authenticated GitHub account does not match the repository owner.' }

if ((Invoke-RepoGit tag --list $Tag) -ne $Tag) {
    Invoke-RepoGit tag -a $Tag $sha -m "SHIFT PROTOCOL $Tag"
}
if ((Invoke-RepoGit rev-parse "$Tag^{commit}").Trim() -ne $sha) { throw 'Existing tag points to another commit.' }
Invoke-RepoGit push origin "refs/tags/$Tag"

$release = $null
try {
    $release = Invoke-RestMethod "$api/releases/tags/$Tag" -Headers $headers
} catch {
    if ($null -eq $_.Exception.Response -or [int]$_.Exception.Response.StatusCode -ne 404) { throw }
}
if (-not $release) {
    $body = @{tag_name=$Tag; target_commitish=$sha; name="SHIFT PROTOCOL $Tag"; body=$Notes; draft=$true} | ConvertTo-Json -Compress
    $release = Invoke-RestMethod "$api/releases" -Method Post -Headers $headers -ContentType 'application/json' -Body $body
}

$assetUrl = $release.upload_url.Split('{')[0]
foreach ($file in $files) {
    $digest = 'sha256:' + (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $asset = $release.assets | Where-Object name -eq $file.Name | Select-Object -First 1
    if (-not $asset) {
        $name = [uri]::EscapeDataString($file.Name)
        $asset = Invoke-RestMethod "${assetUrl}?name=$name" -Method Post -Headers $headers -ContentType 'application/zip' -InFile $file.FullName
    }
    if ($asset.state -ne 'uploaded' -or $asset.size -ne $file.Length -or ($asset.digest -and $asset.digest -ne $digest)) {
        throw "Release asset does not match the build: $($file.Name)"
    }
    Write-Output $asset.browser_download_url
}

if ($release.draft) {
    $body = @{draft=$false; make_latest=$Latest.IsPresent.ToString().ToLowerInvariant()} | ConvertTo-Json -Compress
    $release = Invoke-RestMethod "$api/releases/$($release.id)" -Method Patch -Headers $headers -ContentType 'application/json' -Body $body
}
$public = Invoke-RestMethod "$api/releases/tags/$Tag" -Headers @{'User-Agent'='Shift-Protocol'}
if ($public.draft -or ($public.assets | Where-Object state -eq 'uploaded').Count -lt 2) { throw 'Public release verification failed.' }
Write-Output $public.html_url
