param(
    [string]$Godot = '',
    [switch]$Capture
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
if (-not $Godot) {
    $Godot = Join-Path $projectRoot '.tools/Godot_v4.7.2-stable_win64_console.exe'
}
$Godot = (Resolve-Path -LiteralPath $Godot).Path
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
Push-Location $projectRoot
try {
    $validationData = Join-Path $projectRoot '.tools/userdata'
    New-Item -ItemType Directory -Force $validationData, 'test-output' | Out-Null
    # Review captures may include saved scripts; keep them out of Godot's class registry.
    New-Item -ItemType File -Force (Join-Path $projectRoot 'test-output/.gdignore') | Out-Null
    $env:APPDATA = $validationData
    $env:LOCALAPPDATA = $validationData
    & $Godot --headless --path $projectRoot --editor --import --quit
    if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
    if ($Capture) {
        $captureProcess = Start-Process -FilePath $Godot -ArgumentList '--path . --audio-driver Dummy --rendering-method gl_compatibility tests/integration.tscn -- --capture' -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput 'test-output/capture.log' -RedirectStandardError 'test-output/capture-errors.log'
        Get-Content 'test-output/capture.log', 'test-output/capture-errors.log'
        if ($captureProcess.ExitCode -ne 0) { throw 'Rendered integration checks failed.' }
    } else {
        & $Godot --headless --audio-driver Dummy --path $projectRoot tests/integration.tscn
        if ($LASTEXITCODE -ne 0) { throw 'Integration checks failed.' }
    }
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
    Pop-Location
}
