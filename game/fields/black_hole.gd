class_name BlackHole
extends GravityField
## Schwarzes Loch: zieht stark an (je näher, desto stärker) und verschluckt
## alle Boids, die den Kern erreichen.
##
## Zeigt, wie wenig nötig ist, um aus einem Feld etwas Neues zu machen:
## nur get_force_on() und _draw() überschrieben.

@export var core_radius: float = 30.0


func get_force_on(boid: Boid) -> Vector2:
	var offset := global_position - boid.global_position
	var dist := offset.length()
	if dist >= radius:
		return Vector2.ZERO
	if dist <= core_radius:
		boid.kill()
		return Vector2.ZERO

	var inward := offset / dist
	var closeness := 1.0 - dist / radius  # 0 am Rand … 1 im Zentrum
	var pull := strength * closeness * (0.5 + 2.5 * closeness) * _scale_factor
	# etwas Drehimpuls, damit Boids spiralförmig hineinfallen
	var spin := inward.orthogonal() * pull * swirl * 0.4
	return inward * pull + spin


func _draw() -> void:
	var px := screen_px()
	var a := _scale_factor
	# Wirkbereich
	draw_circle(Vector2.ZERO, radius, Color(color, fill_alpha * 0.8 * a))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, Color(color, 0.35 * a), 2.0 * px, true)
	# Akkretionsscheibe
	var dir := 1.0 if clockwise else -1.0
	var base := _time * 1.6 * dir
	for i in 4:
		var from := base + i * TAU / 4.0
		draw_arc(Vector2.ZERO, core_radius * 1.9, from, from + 1.1, 20, Color(color, 0.85 * a), 4.0 * px, true)
	# Ereignishorizont
	draw_circle(Vector2.ZERO, core_radius, Color(0, 0, 0, 1))
	draw_arc(Vector2.ZERO, core_radius, 0.0, TAU, 40, Color(color, a), 3.0 * px, true)
