extends RefCounted
## A crop can be within its atlas yet still contain pieces of its neighbours.
static func run(check: Callable, frames: SpriteFrames, label: String) -> void:
	var seen: Dictionary = {}
	for animation: StringName in frames.get_animation_names():
		for frame: int in frames.get_frame_count(animation):
			var texture := frames.get_frame_texture(animation, frame) as AtlasTexture
			var key := str(texture.region)
			if seen.has(key):
				continue
			seen[key] = true
			var image := texture.atlas.get_image().get_region(Rect2i(texture.region))
			var bounds := image.get_used_rect()
			check.call(bounds.position.x >= 2 and bounds.position.y >= 2 and bounds.end.x <= image.get_width()-2 and bounds.end.y <= image.get_height()-2, label + " frame has transparent gutters")
			var data := image.get_data()
			var width := image.get_width()
			var count := 0
			var first := -1
			for index: int in width * image.get_height():
				if data[index*4+3] > 0:
					count += 1
					first = index
			var visited := PackedByteArray()
			visited.resize(width * image.get_height())
			var queue := PackedInt32Array([first])
			visited[first] = 1
			var cursor := 0
			while cursor < queue.size():
				var index := queue[cursor]
				cursor += 1
				for next: int in [index-1,index+1,index-width,index+width]:
					if next < 0 or next >= visited.size() or absi(next%width-index%width) > 1:
						continue
					if not visited[next] and data[next*4+3] > 0:
						visited[next] = 1
						queue.append(next)
			check.call(queue.size() == count, label + " frame contains one complete actor without neighbour fragments")
