$root = Split-Path -Parent $PSScriptRoot
$gullPath = Join-Path $root 'data/gull_art.json'
$carryPath = Join-Path $root 'data/gull_carry_art.json'
$gulls = Get-Content -LiteralPath $gullPath -Raw | ConvertFrom-Json -AsHashtable
$carry = Get-Content -LiteralPath $carryPath -Raw | ConvertFrom-Json -AsHashtable

foreach ($id in $carry.Keys) {
    if (-not $gulls.ContainsKey($id)) {
        throw "Unknown gull art id: $id"
    }
    $gulls[$id]['carry'] = $carry[$id]
}

$json = $gulls | ConvertTo-Json -Depth 100
[System.IO.File]::WriteAllText($gullPath, $json + "`n", [System.Text.UTF8Encoding]::new($false))
