@tool
class_name SpawnZone
extends Node2D
## Startpunkt eines Schwarms (Kind von "SwarmSpawns" im Level).

@export var radius: float = 160.0:
	set(v):
		radius = v
		queue_redraw()
## 0 = Standardwert aus dem Level (boids_per_swarm)
@export var boid_count: int = 0

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.5, 0.8, 1.0, 0.08))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.5, 0.8, 1.0, 0.5), 3.0, true)
