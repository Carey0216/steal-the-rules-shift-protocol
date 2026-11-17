param(
    [Parameter(Mandatory = $true)]
    [string] $Godot
)

$ErrorActionPreference = 'Stop'
$enginePath = (Get-Command $Godot -ErrorAction Stop).Source
$projectPath = Split-Path $PSScriptRoot -Parent

function Invoke-Engine {
    param([string[]] $EngineArgs)
    & $enginePath --headless --path $projectPath @EngineArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Godot exited with code $LASTEXITCODE."
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
    Invoke-Engine -EngineArgs @('--export-release', 'Web', "$stage/web/index.html")
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

    $webFiles = @('index.html','index.js','index.pck','index.wasm','notices')
    foreach ($optional in @('index.icon.png','index.apple-touch-icon.png','index.png','index.audio.worklet.js','index.audio.position.worklet.js')) {
        if (Test-Path -LiteralPath "$stage/web/$optional") { $webFiles += $optional }
    }
    $webPaths = @($webFiles | ForEach-Object { "$stage/web/$_" })
    $winPaths = @('ShiftProtocol.exe','runtime','PLAY-ZH.md','notices' | ForEach-Object { "$stage/windows/$_" })
    Compress-Archive -LiteralPath $webPaths -DestinationPath "$stage/shift-protocol-web.zip" -CompressionLevel Optimal
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
