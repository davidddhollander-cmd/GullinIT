extends RefCounted
## Task 027: ground props in the same depth band never share base pixels, and nothing sits inside a stall.

const BAND := 10.0          ## props whose ground lines differ by less than this share a depth band
const TALL_GAP := 8.0       ## tall props (palm, lamp, parasol) keep this much clear base beside low props
const TALL: Array[String] = ["beach_palm", "beach_lamp", "beach_parasol", "beach_parasol_blue", "umbrella"]
const STALLS: Array[String] = ["kiosk", "hotdog_stand"]

static func base_span(prop: Dictionary) -> Vector2:
	# Visible base = opaque columns in the sprite's bottom rows, scaled and centred on prop.x.
	var art: Dictionary = Config.sprites[prop.type]
	var scale_factor: float = float(art.get("visual_scale", 1.0))
	var image: Image = (load(str(art.file)) as Texture2D).get_image()
	var low: int = image.get_height() - 1
	while low > 0 and _row_empty(image, low):
		low -= 1
	var first: int = image.get_width()
	var last: int = -1
	for row: int in range(low - 1, low + 1):
		for col: int in image.get_width():
			if image.get_pixel(col, row).a > 0.0:
				first = mini(first, col)
				last = maxi(last, col)
	var left: float = float(prop.x) - float(art.frame_w) * scale_factor * 0.5
	return Vector2(left + float(first) * scale_factor, left + float(last + 1) * scale_factor)

static func _row_empty(image: Image, row: int) -> bool:
	for col: int in image.get_width():
		if image.get_pixel(col, row).a > 0.0:
			return false
	return true

static func ground_y(prop: Dictionary) -> float:
	return 146.0 if prop.type == "umbrella" else float(prop.get("y", 160))

static func actor_overlaps_prop(spawn: Dictionary, prop: Dictionary) -> bool:
	var half_width: float = 10.0 if spawn.type == "toddler" else 14.0
	var actor_span := Vector2(float(spawn.x)-half_width,float(spawn.x)+half_width)
	var prop_span: Vector2 = base_span(prop)
	return actor_span.x < prop_span.y and prop_span.x < actor_span.y

## Returns "typeA@x / typeB@x" for every offending pair.
static func overlaps(props: Array) -> Array[String]:
	var spans: Array[Vector2] = []
	for prop: Dictionary in props:
		spans.append(base_span(prop))
	var found: Array[String] = []
	for a: int in props.size():
		for b: int in range(a + 1, props.size()):
			var pa: Dictionary = props[a]
			var pb: Dictionary = props[b]
			var stall: bool = pa.type in STALLS or pb.type in STALLS
			var same_band: bool = absf(ground_y(pa) - ground_y(pb)) < BAND
			if not stall and not same_band:
				continue
			var gap: float = TALL_GAP if (pa.type in TALL or pb.type in TALL) and same_band else 0.0
			if spans[a].x < spans[b].y + gap and spans[b].x < spans[a].y + gap:
				found.append("%s@%d / %s@%d" % [pa.type, int(pa.x), pb.type, int(pb.x)])
	return found

static func run(check: Callable) -> void:
	for number: int in range(1, 7):
		var level: Dictionary = Config.read_json("res://data/levels/level_%02d.json" % number)
		var bad: Array[String] = overlaps(level.props)
		check.call(bad.is_empty(), "level %d props do not overlap %s" % [number, str(bad)])
		if number == 5:
			var family: Array = level.spawns.filter(func(spawn: Dictionary) -> bool: return spawn.get("family_id","") == "family_1")
			check.call(family.size()==2 and family.any(func(spawn: Dictionary) -> bool: return spawn.type=="picnic_family") and family.any(func(spawn: Dictionary) -> bool: return spawn.type=="toddler"),"level 5 has one mum and one toddler sharing family_1")
			for spawn: Dictionary in family:
				check.call(float(spawn.x)<float(level.world.promenade_start),"level 5 family stays on open sand")
				for prop: Dictionary in level.props:
					check.call(not actor_overlaps_prop(spawn,prop),"level 5 %s at %d clears %s at %d" % [spawn.type,int(spawn.x),prop.type,int(prop.x)])
					if prop.type in ["kiosk","hotdog_stand","fish_chips_stand","beach_bench"]:
						var busy_x: float = float(prop.get("customer_x",prop.x))
						check.call(absf(float(spawn.x)-busy_x)>=35.0,"level 5 family clears %s customer/bench spot" % prop.type)
	# The checker must catch the original level 5 palm/bench clash.
	var clash: Array = [{"type": "beach_palm", "x": 1230, "y": 148}, {"type": "beach_bench", "x": 1225, "y": 153}]
	check.call(overlaps(clash).size() == 1, "overlap check flags a palm standing on a bench")
