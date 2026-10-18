class_name BeachWind
extends RefCounted
signal gust_warning
var direction: int = 0
var strength: float = 0.0
var base: float = 0.0
var gusts: bool = false
var flip: bool = false
var countdown: float = 0.0
var phase: float = -1.0
var warned: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func setup(level: Dictionary) -> void:
	rng.seed = int(level.seed) + 31
	direction = level.wind.dir
	base = level.wind.strength
	strength = base
	gusts = level.wind.gusts
	flip = level.wind.flip
	_next()

func _next() -> void:
	countdown = rng.randf_range(Config.tuning.wind.gust_min, Config.tuning.wind.gust_max)
	warned = false
	phase = -1.0

func tick(delta: float) -> void:
	if not gusts:
		return
	var t: Dictionary = Config.tuning.wind
	if phase < 0:
		countdown -= delta
		if countdown <= float(t.warning) and not warned:
			warned = true
			gust_warning.emit()
		if countdown <= 0:
			phase = 0
			if flip:
				direction *= -1
	else:
		phase += delta
		var ramp: float = float(t.ramp)
		var amount: float = minf(phase / ramp, 1.0)
		if phase > ramp + float(t.hold):
			amount = maxf(0.0, 1.0 - (phase - ramp - float(t.hold)) / ramp)
		strength = base * lerpf(1.0, float(t.multiplier), amount)
		if phase >= ramp * 2 + float(t.hold):
			strength = base
			_next()
