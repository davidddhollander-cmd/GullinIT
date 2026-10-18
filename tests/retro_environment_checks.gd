class_name RetroEnvironmentChecks
extends RefCounted

const TYPES := [
	"bin", "kiosk", "hotdog_stand", "tower", "umbrella",
	"beach_parasol", "beach_parasol_blue", "beach_chair", "beach_chair_blue",
	"beach_bench", "beach_palm", "beach_sign", "beach_castle",
	"beach_rocks", "beach_boards", "beach_hut", "beach_lamp"
]

static func run_checks(check: Callable) -> void:
	for kind: String in TYPES:
		var definition: Dictionary = Config.sprites[kind]
		var path: String = definition.file
		check.call(path.begins_with("res://assets/sprites/retro-") and FileAccess.file_exists(path), "%s uses generated native-pixel art" % kind)
		var texture: Texture2D = load(path) as Texture2D
		check.call(texture != null, "%s texture opens" % kind)
		if texture == null:
			continue
		var image: Image = texture.get_image()
		check.call(image.get_width() == int(definition.frame_w) and image.get_height() == int(definition.frame_h), "%s sprite dimensions match its atlas metadata" % kind)
		var colours: Dictionary = {}
		var binary_alpha: bool = true
		for y: int in image.get_height():
			for x: int in image.get_width():
				var pixel: Color = image.get_pixel(x, y)
				if pixel.a > 0.0 and pixel.a < 1.0:
					binary_alpha = false
				if pixel.a > 0.0:
					colours[pixel.to_html(false)] = true
		check.call(binary_alpha, "%s has hard transparent/opaque edges" % kind)
		check.call(colours.size() <= 16, "%s stays within the shared 16-colour palette" % kind)
