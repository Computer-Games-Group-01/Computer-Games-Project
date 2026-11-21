@tool
class_name CircleObstacle
extends Obstacle

@export var radius: float = 120.0:
	set(value):
		radius = maxf(value, 1.0)
		queue_redraw()


func surface_distance(world_point: Vector2) -> float:
	return global_position.distance_to(world_point) - radius


func surface_normal(world_point: Vector2) -> Vector2:
	var offset := world_point - global_position
	return offset.normalized() if offset.length_squared() > 0.0001 else Vector2.UP


func bounding_radius() -> float:
	return radius


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, edge_color, 3.0, true)
	if Engine.is_editor_hint():  # Ausweich-Zone nur im Editor andeuten
		draw_arc(Vector2.ZERO, radius + margin, 0.0, TAU, 64, Color(edge_color, 0.25), 2.0, true)
