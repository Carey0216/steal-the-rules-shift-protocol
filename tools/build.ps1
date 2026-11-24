param(
    [Parameter(Mandatory = $true)]
    [string] $Godot
)

$ErrorActionPreference = 'Stop'
$enginePath = (Get-Command $Godot -ErrorAction Stop).Source
$projectPath = Split-Path $PSScriptRoot -Parent

function Invoke-Engine {
    param([string[]] $EngineArgs)
    $engineOutput = & $enginePath --headless --path $projectPath @EngineArgs 2>&1
    $engineExit = $LASTEXITCODE
    $engineOutput | ForEach-Object { Write-Output $_ }
    if ($engineExit -ne 0 -or ($engineOutput -match 'SCRIPT ERROR:|^ERROR:')) {
        throw "Godot check failed (exit $engineExit). Review the errors above."
    }
}

$buildRoot = Join-Path $projectPath 'builds'
$stage = Join-Path $buildRoot ('.staging-' + [guid]::NewGuid().ToString('N'))
$outputs = @('web','windows','shift-protocol-web.zip','shift-protocol-windows-x64.zip')
$stageCleanup = $true

function Assert-BuildPath {
    param([string] $Path)
    $resolved = (Get-Item -LiteralPath $Path -Force -ErrorAction Stop).FullName
    if (-not $resolved.StartsWith($buildRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Output is outside the builds directory: $resolved"
    }
    if ((Get-Item -LiteralPath $resolved -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "Output is a reparse point: $resolved"
    }
}

Push-Location $projectPath
try {
    New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null
    $buildRoot = (Get-Item -LiteralPath $buildRoot -Force).FullName
    if ((Get-Item -LiteralPath $buildRoot -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "Build directory is a reparse point: $buildRoot"
    }
    New-Item -ItemType Directory -Path "$stage/web","$stage/windows/runtime","$stage/previous" -Force | Out-Null
    New-Item -ItemType File -Path 'builds/.gdignore' -Force | Out-Null
    Invoke-Engine -EngineArgs @('--import')
    Invoke-Engine -EngineArgs @('--script', 'tests/smoke.gd')
    Invoke-Engine -EngineArgs @('--script', 'tests/release.gd')
    Invoke-Engine -EngineArgs @('--script', 'tests/guide_skip.gd')
    Invoke-Engine -EngineArgs @('--export-release', 'Web', "$stage/web/index.html")
    $webHtml = Join-Path $stage 'web/index.html'
    $packHash = (Get-FileHash -LiteralPath "$stage/web/index.pck" -Algorithm SHA256).Hash.ToLowerInvariant()
    $webParts = @{}
    New-Item -ItemType Directory -Path "$stage/web/parts" -Force | Out-Null
    foreach ($kind in @('pck','wasm')) {
        $payload = [IO.File]::ReadAllBytes("$stage/web/index.$kind")
        $parts = @()
        for ($offset = 0; $offset -lt $payload.Length; $offset += 1MB) {
            $count = [Math]::Min(1MB, $payload.Length - $offset)
            $chunk = [byte[]]::new($count)
            [Array]::Copy($payload, $offset, $chunk, 0, $count)
            $name = 'parts/{0}-{1:d3}.{0}' -f $kind, [int]($offset / 1MB)
            [IO.File]::WriteAllBytes("$stage/web/$name", $chunk)
            $hash = (Get-FileHash -LiteralPath "$stage/web/$name" -Algorithm SHA256).Hash.ToLowerInvariant()
            $parts += @{file=$name; size=$count; sha256=$hash}
        }
        $webParts[$kind] = $parts
    }
    $partManifest = $webParts | ConvertTo-Json -Depth 5 -Compress
    $shell = [IO.File]::ReadAllText($webHtml).Replace('$SHIFT_PACK_SHA256', $packHash).Replace('$SHIFT_WEB_PARTS', $partManifest)
    [IO.File]::WriteAllText($webHtml, $shell, [Text.UTF8Encoding]::new($false))
    Invoke-Engine -EngineArgs @('--export-release', 'Windows', "$stage/windows/runtime/ShiftProtocolGame.exe")
    $csc = Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
    if (-not (Test-Path -LiteralPath $csc -PathType Leaf)) { throw 'The Windows launcher requires the .NET Framework C# compiler.' }
    $launcherOut = Join-Path (Get-Item -LiteralPath "$stage/windows").FullName 'ShiftProtocol.exe'
    $launcherSource = (Get-Item -LiteralPath 'tools/windows/Launcher.cs').FullName
    & $csc /nologo /target:winexe /platform:x64 /optimize+ "/out:$launcherOut" $launcherSource
    if ($LASTEXITCODE -ne 0) { throw 'Could not compile the Windows launcher.' }

    $notices = @('LICENSE','docs/GODOT_LICENSE.txt','docs/GODOT_COPYRIGHT.txt')
    $notices += @(Get-ChildItem -Path 'assets/OFL-*.txt' -File | Select-Object -ExpandProperty FullName)
    foreach ($target in @('web','windows')) {
        $noticePath = "$stage/$target/notices"
        New-Item -ItemType Directory -Path $noticePath -Force | Out-Null
        Copy-Item -LiteralPath $notices -Destination $noticePath -Force
    }
    Copy-Item -LiteralPath 'docs/PLAY-ZH.md' -Destination "$stage/windows/PLAY-ZH.md"
    Copy-Item -LiteralPath 'docs/PLAY-EN.md' -Destination "$stage/windows/README.md"
    Copy-Item -LiteralPath 'docs/CAMPAIGN-48-ZH.md' -Destination "$stage/windows/CAMPAIGN-48-ZH.md"

    $webFiles = @('index.html','index.js','parts','notices')
    foreach ($optional in @('index.icon.png','index.apple-touch-icon.png','index.png','index.audio.worklet.js','index.audio.position.worklet.js')) {
        if (Test-Path -LiteralPath "$stage/web/$optional") { $webFiles += $optional }
    }
    $webPaths = @($webFiles | ForEach-Object { "$stage/web/$_" })
    $winPaths = @('ShiftProtocol.exe','runtime','README.md','PLAY-ZH.md','CAMPAIGN-48-ZH.md','notices' | ForEach-Object { "$stage/windows/$_" })
    Compress-Archive -LiteralPath $webPaths -DestinationPath "$stage/shift-protocol-web.zip" -CompressionLevel Optimal
    # itch.io recognizes gzip data under its original filename and serves the encoding header.
    # Keep the unpacked build untouched so it also works on ordinary local HTTP servers.
    Add-Type -AssemblyName System.IO.Compression
    $webZip = [IO.Compression.ZipFile]::Open("$stage/shift-protocol-web.zip", [IO.Compression.ZipArchiveMode]::Update)
    try {
        foreach ($part in $webParts['wasm']) {
            $webZip.GetEntry($part.file).Delete()
            $wasmEntry = $webZip.CreateEntry($part.file, [IO.Compression.CompressionLevel]::NoCompression)
            $entryStream = $wasmEntry.Open()
            $gzip = [IO.Compression.GZipStream]::new($entryStream, [IO.Compression.CompressionLevel]::Optimal, $false)
            $wasmSource = [IO.File]::OpenRead("$stage/web/$($part.file)")
            try { $wasmSource.CopyTo($gzip) } finally { $wasmSource.Dispose(); $gzip.Dispose() }
        }
    } finally { $webZip.Dispose() }
    Compress-Archive -LiteralPath $winPaths -DestinationPath "$stage/shift-protocol-windows-x64.zip" -CompressionLevel Optimal
    $backedUp = @()
    $published = @()
    try {
        foreach ($name in $outputs) {
            $old = Join-Path $buildRoot $name
            if (Test-Path -LiteralPath $old) {
                Assert-BuildPath $old
                Move-Item -LiteralPath $old -Destination "$stage/previous/$name"
                $backedUp += $name
            }
            Assert-BuildPath "$stage/$name"
            Move-Item -LiteralPath "$stage/$name" -Destination $old
            $published += $name
        }
    } catch {
        $stageCleanup = $false
        foreach ($name in $published) {
            Assert-BuildPath "$buildRoot/$name"
            Move-Item -LiteralPath "$buildRoot/$name" -Destination "$stage/$name"
        }
        foreach ($name in $backedUp) {
            Assert-BuildPath "$stage/previous/$name"
            Move-Item -LiteralPath "$stage/previous/$name" -Destination "$buildRoot/$name"
        }
        $stageCleanup = $true
        throw
    }
    Get-Item 'builds/shift-protocol-web.zip','builds/shift-protocol-windows-x64.zip' | Select-Object Name,Length
} finally {
    if ($stageCleanup -and (Test-Path -LiteralPath $stage)) {
        Assert-BuildPath $stage
        Remove-Item -LiteralPath $stage -Recurse -Force
    }
    Pop-Location
}
