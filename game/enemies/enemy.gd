@tool
class_name Enemy
extends Influencer
## Jäger: patrouilliert, verfolgt Boids in Sichtweite, tötet bei Berührung.

@export var kill_radius: float = 40.0:
	set(v):
		kill_radius = v
		queue_redraw()
@export var scare_radius: float = 320.0:
	set(v):
		scare_radius = v
		queue_redraw()
@export var scare_strength: float = 1200.0
@export var patrol_speed: float = 120.0
## Muss über der Boid-Geschwindigkeit liegen (ca. 190-230), sonst fängt er nichts.
@export var chase_speed: float = 260.0
## 0 = verfolgt nicht (reine Falle/Wächter)
@export var sight_range: float = 500.0
## Patrouillenpunkte relativ zur Startposition. Leer = steht still.
@export var patrol_offsets: Array[Vector2] = []

var flock: FlockManager  # setzt Level._ready()
var _home: Vector2
var _home_set: bool = false
var _patrol_index: int = 0


func get_reach() -> float:
	# kill_radius darf nie größer sein als die Reichweite, sonst wird nie getötet
	return maxf(scare_radius, kill_radius)


## Wird vom FlockManager nur für Boids innerhalb von get_reach() aufgerufen.
func get_force_on(boid: Boid) -> Vector2:
	var away := boid.position - global_position
	var d := away.length()
	if d <= kill_radius:
		boid.kill()
		return Vector2.ZERO
	if d >= scare_radius:
		return Vector2.ZERO
	return away / d * scare_strength * (1.0 - d / scare_radius)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not _home_set:
		_home = global_position
		_home_set = true

	var prey := _nearest_boid()
	if prey != null:
		global_position = global_position.move_toward(prey.position, chase_speed * delta)
		return
	if patrol_offsets.is_empty():
		return
	var goal := _home + patrol_offsets[_patrol_index]
	global_position = global_position.move_toward(goal, patrol_speed * delta)
	if global_position.distance_to(goal) < 4.0:
		_patrol_index = (_patrol_index + 1) % patrol_offsets.size()


func _nearest_boid() -> Boid:
	if flock == null or sight_range <= 0.0:
		return null
	var best: Boid = null
	var best_d := INF
	for b in flock.get_boids_in_circle(global_position, sight_range):
		var d := b.position.distance_squared_to(global_position)
		if d < best_d:
			best_d = d
			best = b
	return best


func _draw() -> void:
	draw_circle(Vector2.ZERO, scare_radius, Color(1, 0.3, 0.3, 0.05))
	draw_arc(Vector2.ZERO, scare_radius, 0.0, TAU, 48, Color(1, 0.3, 0.3, 0.25), 2.0, true)
	draw_circle(Vector2.ZERO, kill_radius, Color(1, 0.25, 0.25, 0.9))
