@tool
class_name GoalZone
extends Node2D
## Ziel: Jeder Boid im Kreis gilt als gerettet und verschwindet.

signal boids_rescued(amount: int)

@export var radius: float = 240.0:
	set(v):
		radius = v
		queue_redraw()
@export var color: Color = Color("81c784")

var flock: FlockManager  # setzt Level._ready()
var rescued: int = 0

func _process(_delta: float) -> void:
	if flock == null:
		return
	var caught := flock.get_boids_in_circle(global_position, radius)
	if caught.is_empty():
		return
	for boid in caught:
		boid.kill()  # alive = false -> wird nicht doppelt gezählt
	rescued += caught.size()
	boids_rescued.emit(caught.size())

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(color, 0.12))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(color, 0.8), 4.0, true)
