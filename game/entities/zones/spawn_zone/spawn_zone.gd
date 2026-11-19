@tool
class_name SpawnZone
extends Marker2D
## Start point of a swarm. Spawns the swarm as soon as World calls setup().

@export var radius: float = 160.0:
	set(v):
		radius = v
		queue_redraw()
## Number of boids in this swarm.
@export var boid_count: int = 60


func _ready() -> void:
	add_to_group(&"uses_boids")


func setup(boid_world: BoidWorld) -> void:
	boid_world.spawn_swarm(global_position, boid_count, radius)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.5, 0.8, 1.0, 0.08))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.5, 0.8, 1.0, 0.5), 3.0, true)
