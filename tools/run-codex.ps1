# Delegate to Codex: runs "Process the task queue." non-interactively in this repo.
# Usage: ./tools/run-codex.ps1 [-Prompt "custom prompt"]
param([string]$Prompt = "Process the task queue.")

$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

if (Test-Path tasks/LOCK) {
    Write-Host "tasks/LOCK exists, another agent is working:"
    Get-Content tasks/LOCK
    exit 1
}
if (-not (Get-ChildItem tasks/inbox -Filter *.md -ErrorAction SilentlyContinue)) {
    Write-Host "tasks/inbox is empty, nothing to delegate."
    exit 0
}

New-Item -ItemType Directory -Force test-output | Out-Null
$log = "test-output/codex-run.log"   # ignored by git
codex exec --full-auto $Prompt 2>&1 | Tee-Object -FilePath $log
Write-Host "`nExit: $LASTEXITCODE  (log: $log). Now: Review the task queue."
exit $LASTEXITCODE
