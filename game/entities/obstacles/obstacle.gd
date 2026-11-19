@tool
class_name Obstacle
extends Influencer
## Basisklasse für Hindernisse. Boids weichen weich aus (Kraft im Bereich `margin`)
## und können zusätzlich nie hinein (harte Korrektur als Sicherheitsnetz).
##
## Eine neue Form = nur diese drei Funktionen überschreiben:
##   surface_distance(p)  Abstand zur Oberfläche (negativ = innen)
##   surface_normal(p)    Richtung von der Oberfläche weg
##   bounding_radius()    Radius eines Kreises um die Position, der die Form umschließt
## (Skalierung der Node bitte bei (1, 1) lassen – Größe über die Exporte einstellen.)

## Ab diesem Abstand zur Oberfläche beginnen Boids auszuweichen.
@export var margin: float = 110.0
@export var strength: float = 2200.0
@export var fill_color: Color = Color(0.17, 0.2, 0.3)
@export var edge_color: Color = Color(0.45, 0.55, 0.8)


func _init() -> void:
	solid = true


func surface_distance(_world_point: Vector2) -> float:
	return INF


func surface_normal(_world_point: Vector2) -> Vector2:
	return Vector2.UP


func bounding_radius() -> float:
	return 0.0


func get_reach() -> float:
	return bounding_radius() + margin


func get_force_on(boid: Boid) -> Vector2:
	var p := boid.global_position
	var d := surface_distance(p)
	if d >= margin:
		return Vector2.ZERO
	var n := surface_normal(p)
	var t := 1.0 - clampf(d / margin, 0.0, 1.0)
	t *= t  # weicher Einsatz, am Rand der Form volle Stärke
	# Zusätzlich entlang der Oberfläche schieben, damit Boids herumfließen statt abzuprallen.
	var along := boid.velocity - n * boid.velocity.dot(n)
	var slide := along.normalized() if along.length_squared() > 1.0 else n.orthogonal()
	return (n + slide * 0.6) * strength * t


func constrain(boid: Boid) -> void:
	var p := boid.global_position
	var d := surface_distance(p)
	if d >= 0.0:
		return
	var n := surface_normal(p)
	boid.global_position = p + n * (-d + 1.0)
	var into := boid.velocity.dot(n)
	if into < 0.0:
		boid.velocity -= n * into
