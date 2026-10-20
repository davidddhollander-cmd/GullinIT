# Update metadata after prepare_retro_environment.gd generates native PNGs.
$spritePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'data/sprites.json'
$sprites = Get-Content -LiteralPath $spritePath -Raw | ConvertFrom-Json -AsHashtable
$sizes = [ordered]@{
    bin = @(16, 22)
    kiosk = @(52, 56)
    hotdog_stand = @(52, 56)
    tower = @(56, 70)
    umbrella = @(38, 42)
    beach_parasol = @(40, 42)
    beach_parasol_blue = @(40, 42)
    beach_chair = @(24, 23)
    beach_chair_blue = @(24, 23)
    beach_bench = @(42, 22)
    beach_palm = @(44, 62)
    beach_sign = @(34, 44)
    beach_castle = @(30, 22)
    beach_rocks = @(44, 18)
    beach_boards = @(32, 44)
    beach_hut = @(40, 52)
}
# The taller, curated lamp has its own preparation script and perch alignment.
# Preserve its metadata when rebuilding the original environment sheet.
foreach ($name in $sizes.Keys) {
    $definition = $sprites[$name]
    $slug = $name.Replace('_', '-')
    $definition['file'] = "res://assets/sprites/retro-$slug-32bit.png"
    $definition['frame_w'] = $sizes[$name][0]
    $definition['frame_h'] = $sizes[$name][1]
    $definition.Remove('visual_scale')
    $definition.Remove('regions')
    $definition['animations'] = [ordered]@{ idle = [ordered]@{ frames = @(0); fps = 1; loop = $true } }
}
$json = $sprites | ConvertTo-Json -Depth 100
[System.IO.File]::WriteAllText($spritePath, $json + "`n", [System.Text.UTF8Encoding]::new($false))
