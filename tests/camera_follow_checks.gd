extends RefCounted
## Camera dead zone, damped follow and hard screen margin, at three physics rates.

static func run(check: Callable) -> void:
	var w: Dictionary = Config.tuning.world
	var dz: float = float(w.camera_dead_zone_x)
	var margin: float = float(w.camera_margin_x)
	var hi: float = float(w.width)-160.0
	for hz: int in [30,60,120]:
		var dt: float = 1.0/hz
		# Wobble inside the dead zone: camera never moves.
		var cam := Vector2(400.0,0.0)
		var moved: bool = false
		for i in hz*2:
			var gull: float = 400.0+sin(i*0.7)*(dz-1.0)
			cam = CameraFollow.step(cam.x,cam.y,gull,gull,160.0,dz,float(w.camera_smooth_time),margin,160.0,hi,dt)
			moved = moved or cam.x != 400.0
		check.call(not moved,"Camera still for gull wobble inside dead zone at %dHz" % hz)
		# Gull walks steadily away: camera follows smoothly (no reversal, no jump bigger than gull travel) and catches up.
		var gull_x: float = 400.0
		var smooth: bool = true
		for i in hz*3:
			gull_x += 60.0*dt
			var before: float = cam.x
			cam = CameraFollow.step(cam.x,cam.y,gull_x,gull_x,160.0,dz,float(w.camera_smooth_time),margin,160.0,hi,dt)
			smooth = smooth and cam.x >= before and cam.x-before <= 60.0*dt*2.0
		check.call(smooth and absf(gull_x-cam.x) <= dz+60.0*float(w.camera_smooth_time)+2.0,"Camera follows steady walk smoothly at %dHz" % hz)
		# Max dive + max tailwind, both directions: gull never leaves the margin.
		var top: float = float(Config.tuning.dive.max_speed)+float(Config.tuning.wind.dive_tailwind)
		for dir: float in [1.0,-1.0]:
			cam = Vector2(640.0,0.0)
			gull_x = 640.0
			var worst: float = 0.0
			while gull_x > 160.0 and gull_x < hi:
				gull_x += dir*top*dt
				cam = CameraFollow.step(cam.x,cam.y,clampf(gull_x,160.0,hi),gull_x,160.0,dz,float(w.camera_smooth_time),margin,160.0,hi,dt)
				worst = maxf(worst,absf(gull_x-cam.x))
			check.call(worst <= 160.0-margin+0.01,"Gull stays inside %dpx margin at max speed %d dir %d at %dHz" % [margin,top,dir,hz])
