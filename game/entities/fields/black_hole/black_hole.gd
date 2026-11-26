class_name BlackHole
extends GravityField
## Black hole: pulls hard (the closer, the stronger) and swallows every boid that reaches the core.
##
## Shows how little a new field type needs: only [method _compute_force] and [method _draw]
## are overridden. Fade-in, lifetime and decay come from [GravityField].

## Radius (px) of the core. Boids that reach it die.
@export var core_radius: float = 30.0


func _compute_force(boid: Boid) -> Vector2:
	var offset := global_position - boid.global_position
	var dist := offset.length()
	if dist >= radius:
		return Vector2.ZERO
	if dist <= core_radius:
		boid.kill()
		return Vector2.ZERO

	var inward := offset / dist
	var closeness := 1.0 - dist / radius  # 0 at the edge … 1 at the centre
	var pull := strength * closeness * (0.5 + 2.5 * closeness)
	# Some angular momentum, so boids spiral in.
	var spin := inward.orthogonal() * pull * swirl * 0.4
	return inward * pull + spin


func _draw() -> void:
	var px := screen_px()
	var a := spawn_alpha()
	# Area of effect
	draw_circle(Vector2.ZERO, radius, Color(color, fill_alpha * 0.8 * a))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, Color(color, 0.35 * a), 2.0 * px, true)
	# Accretion disk
	var dir := 1.0 if clockwise else -1.0
	var base := _time * 1.6 * dir
	for i in 4:
		var from := base + i * TAU / 4.0
		draw_arc(Vector2.ZERO, core_radius * 1.9, from, from + 1.1, 20, Color(color, 0.85 * a), 4.0 * px, true)
	# Event horizon
	draw_circle(Vector2.ZERO, core_radius, Color(0, 0, 0, 1))
	draw_arc(Vector2.ZERO, core_radius, 0.0, TAU, 40, Color(color, a), 3.0 * px, true)
