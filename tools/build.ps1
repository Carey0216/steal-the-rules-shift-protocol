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

Push-Location $projectPath
try {
    New-Item -ItemType Directory -Path 'builds/web','builds/windows' -Force | Out-Null
    New-Item -ItemType File -Path 'builds/.gdignore' -Force | Out-Null
    Invoke-Engine -EngineArgs @('--import')
    Invoke-Engine -EngineArgs @('--script', 'tests/smoke.gd')
    Invoke-Engine -EngineArgs @('--export-release', 'Web', (Join-Path $projectPath 'builds/web/index.html'))
    Invoke-Engine -EngineArgs @('--export-release', 'Windows', (Join-Path $projectPath 'builds/windows/ShiftProtocol.exe'))

    $notices = @('LICENSE','assets/OFL-BarlowCondensed.txt','assets/OFL-SpaceMono.txt','docs/GODOT_LICENSE.txt','docs/GODOT_COPYRIGHT.txt')
    foreach ($target in @('web','windows')) {
        $noticePath = "builds/$target/notices"
        New-Item -ItemType Directory -Path $noticePath -Force | Out-Null
        Copy-Item -LiteralPath $notices -Destination $noticePath -Force
    }
    Copy-Item -LiteralPath 'docs/PLAY-ZH.md' -Destination 'builds/windows/PLAY-ZH.md' -Force

    $webFiles = @('index.html','index.js','index.pck','index.wasm','notices')
    foreach ($optional in @('index.icon.png','index.apple-touch-icon.png','index.png','index.audio.worklet.js','index.audio.position.worklet.js')) {
        if (Test-Path -LiteralPath "builds/web/$optional") { $webFiles += $optional }
    }
    $webPaths = @($webFiles | ForEach-Object { "builds/web/$_" })
    $winPaths = @('ShiftProtocol.exe','ShiftProtocol.pck','PLAY-ZH.md','notices' | ForEach-Object { "builds/windows/$_" })
    Compress-Archive -LiteralPath $webPaths -DestinationPath 'builds/shift-protocol-web.zip' -CompressionLevel Optimal -Force
    Compress-Archive -LiteralPath $winPaths -DestinationPath 'builds/shift-protocol-windows-x64.zip' -CompressionLevel Optimal -Force
    Get-Item 'builds/shift-protocol-web.zip','builds/shift-protocol-windows-x64.zip' | Select-Object Name,Length
} finally {
    Pop-Location
}
