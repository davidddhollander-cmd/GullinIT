class_name BackgroundBirds
extends Node2D
## Tiny far-off bird flocks (2-3 birds, 3-5 px wide) for the generated sky, drawn in code.
## One flock crosses the sky per CYCLE, with a gap before the next. Everything is a pure
## function of the beach clock, so it is deterministic and freezes with pause.
## Positions are screen-space; the parent BeachBackgroundArt pins this node to the camera.

const CYCLE: float = 60.0
## Latest a flock may enter within its cycle; keeps every crossing inside one CYCLE.
const MAX_START: float = 12.0
const POSE_TIME: float = 0.5
const SCREEN_W: float = 320.0
## Enter/leave this far off-screen so the whole formation is hidden.
const MARGIN: float = 18.0
const SEED: int = 8210
const DAY_COLOR: Color = Color8(46, 94, 118)
const DUSK_COLOR: Color = Color8(88, 48, 66)
## Wing pixels per bird size (small, large), per pose: "v", flat, "^". Offsets from the bird's centre.
const WINGS: Array = [
	[[Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)],
	[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)],
	[Vector2i(-1, 1), Vector2i(1, 1), Vector2i(0, 0)]],
	[[Vector2i(-2, 0), Vector2i(2, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	[Vector2i(-2, 1), Vector2i(2, 1), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)]],
]
const POSE_CYCLE: Array[int] = [0, 1, 2, 1]
const FORMATION_DY: Array[int] = [0, 2, -2]

var color: Color
## Lit pixels this frame, in screen coordinates.
var pixels: PackedVector2Array = PackedVector2Array()

func _init(sunset: bool) -> void:
	color = DUSK_COLOR if sunset else DAY_COLOR

func update(time: float) -> void:
	var cells := PackedVector2Array()
	var k: int = floori(time / CYCLE)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + k
	var start: float = rng.randf() * MAX_START
	var dir: float = 1.0 if rng.randf() < 0.5 else -1.0
	var speed: float = rng.randf_range(8.0, 11.0)
	# Two bands, above and below the sun's disc (x 233-267, y 26-60), so no flock crosses it.
	var lane: int = rng.randi_range(19, 21) if rng.randf() < 0.5 else rng.randi_range(66, 70)
	var bob_phase: float = rng.randf() * TAU
	var count: int = rng.randi_range(2, 3)
	var local: float = time - k * CYCLE - start
	var travelled: float = local * speed
	if local >= 0.0 and travelled < SCREEN_W + 2.0 * MARGIN:
		var lead_x: float = travelled - MARGIN if dir > 0.0 else SCREEN_W + MARGIN - travelled
		# Slow 1 px bob: only when the sine passes ~0.6, so it happens now and then.
		var bob: int = roundi(0.8 * sin(local * 0.4 + bob_phase))
		for i: int in count:
			var size: int = rng.randi_range(0, 1)
			var phase: int = rng.randi_range(0, 3)
			var jitter: int = rng.randi_range(-1, 1)
			var centre := Vector2i(floori(lead_x) - int(dir) * (i * 6 + absi(jitter)), lane + bob + FORMATION_DY[i] + jitter)
			var pose: int = POSE_CYCLE[(int(time / POSE_TIME) + phase) % 4]
			for offset: Vector2i in WINGS[size][pose]:
				var at: Vector2i = centre + offset
				if at.x >= 0 and at.x < int(SCREEN_W):
					cells.append(Vector2(at))
	if cells != pixels:
		pixels = cells
		queue_redraw()

func _draw() -> void:
	for at: Vector2 in pixels:
		draw_rect(Rect2(at, Vector2.ONE), color)
