@tool
class_name RectObstacle
extends Obstacle
## Rechteck, beliebig drehbar (Rotation der Node im Editor). Gut für Wände.

@export var size: Vector2 = Vector2(400.0, 60.0):
	set(value):
		size = value.max(Vector2.ONE)
		queue_redraw()


func surface_distance(world_point: Vector2) -> float:
	var q := to_local(world_point).abs() - size * 0.5
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0)


func surface_normal(world_point: Vector2) -> Vector2:
	var l := to_local(world_point)
	var q := l.abs() - size * 0.5
	var n_local: Vector2
	if q.x > 0.0 or q.y > 0.0:
		# außerhalb: vom nächsten Punkt des Rechtecks weg
		n_local = Vector2(maxf(q.x, 0.0) * signf(l.x), maxf(q.y, 0.0) * signf(l.y)).normalized()
	elif q.x > q.y:
		n_local = Vector2(1.0 if l.x >= 0.0 else -1.0, 0.0)   # innen: zur nächsten Kante
	else:
		n_local = Vector2(0.0, 1.0 if l.y >= 0.0 else -1.0)
	return global_transform.basis_xform(n_local).normalized()


func bounding_radius() -> float:
	return size.length() * 0.5


func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	draw_rect(rect, fill_color)
	draw_rect(rect, edge_color, false, 3.0)
