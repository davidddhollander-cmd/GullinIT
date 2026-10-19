# Keep Config.frames metadata aligned with the approved 128-pixel source atlases.
$spritePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'data/sprites.json'
$sprites = Get-Content -LiteralPath $spritePath -Raw | ConvertFrom-Json -AsHashtable
$mumClips = [ordered]@{
    idle = 4; eat = 4; walk = 6; walk_left = 6
    alert = 4; block = 4; shield = 4; swat = 6
    chase = 6; chase_left = 6; kick = 6; kick_left = 6
    carry = 6; carry_left = 6; handover = 5
}
$sunClips = [ordered]@{
    rest = 4; rise = 7; idle = 4; eat = 4
    walk = 6; walk_left = 6; alert = 4; block = 4
    swat = 6; chase = 6; chase_left = 6
    kick = 6; kick_left = 6; pickup = 5; run = 7; run_left = 7
}
foreach ($spec in @(
    @{ id = 'parent'; file = 'res://assets/sprites/retro-mum-32bit.png'; clips = $mumClips },
    @{ id = 'sunbather'; file = 'res://assets/sprites/retro-sunbather-male-red-32bit.png'; clips = $sunClips }
)) {
    $definition = $sprites[$spec.id]
    $definition['file'] = $spec.file
    $definition['frame_w'] = 128
    $definition['frame_h'] = 128
    $definition.Remove('visual_scale')
    $definition.Remove('regions')
    $animations = [ordered]@{}
    $index = 0
    foreach ($name in $spec.clips.Keys) {
        $count = $spec.clips[$name]
        $loop = $name -in @('rest', 'idle', 'eat', 'walk', 'walk_left', 'chase', 'chase_left', 'carry', 'carry_left', 'run', 'run_left')
        $fps = if ($name -in @('chase', 'chase_left', 'run', 'run_left')) { 12 } elseif ($name -in @('walk', 'walk_left', 'carry', 'carry_left')) { 10 } elseif ($name -eq 'rest') { 4 } elseif ($name -eq 'idle') { 6 } else { 8 }
        $animations[$name] = [ordered]@{ frames = @($index..($index + $count - 1)); fps = $fps; loop = $loop }
        $index += $count
    }
    $definition['animations'] = $animations
}
$json = $sprites | ConvertTo-Json -Depth 100
[System.IO.File]::WriteAllText($spritePath, $json + "`n", [System.Text.UTF8Encoding]::new($false))
