extends RefCounted
## Review-only gait driver. Distance is measured before crowd visual offsets.
var phase: float = 0
var stride: float = 36

func advance_distance(distance: float) -> int:
	phase = fposmod(phase+absf(distance)/stride,1)
	return frame()

func frame() -> int:
	return mini(7,int(phase*8))

func plant() -> int:
	phase = 0.0 if phase<0.25 or phase>=0.75 else 0.5
	return frame()
