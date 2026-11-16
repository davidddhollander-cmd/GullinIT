class_name CameraFollow
extends RefCounted
## One camera axis: dead zone, critically damped follow, and a hard margin that keeps the subject on screen.

## pos/vel: camera state. target: where the camera wants to centre. subject: the gull on this axis.
## half: half the screen on this axis. Returns Vector2(new_pos, new_vel).
static func step(pos: float, vel: float, target: float, subject: float, half: float, dead_zone: float, smooth_time: float, margin: float, lo: float, hi: float, dt: float) -> Vector2:
	var goal: float = pos
	if absf(target-pos) > dead_zone:
		goal = target-signf(target-pos)*dead_zone
	var omega: float = 2.0/maxf(smooth_time,0.001)
	var x: float = omega*dt
	var decay: float = 1.0/(1.0+x+0.48*x*x+0.235*x*x*x)
	var change: float = pos-goal
	var temp: float = (vel+omega*change)*dt
	var next: float = goal+(change+temp)*decay
	var speed: float = (vel-omega*temp)*decay
	var reach: float = half-margin
	next = clampf(clampf(next,subject-reach,subject+reach),lo,hi)
	if dt > 0.0:
		speed = (next-pos)/dt # no wind-up while the hard margin or level edge is holding the camera
	return Vector2(next,speed)
