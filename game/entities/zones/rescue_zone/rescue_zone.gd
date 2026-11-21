@tool
class_name RescueZone
extends BoidZone
## Goal: every boid inside the circle counts as rescued and disappears.

@export var radius: float = 240.0:
	set(v):
		radius = v
		queue_redraw()
@export var color: Color = Color("81c784")


func _process(_delta: float) -> void:
	if boids == null:
		return
	var caught := boids.query_circle(global_position, radius)
	if not caught.is_empty():
		boids.rescue(caught)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(color, 0.12))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(color, 0.8), 4.0, true)
