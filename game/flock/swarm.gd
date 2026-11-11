class_name Swarm
extends RefCounted
## Eine Gruppe zusammengehöriger Boids. Alignment und Cohesion wirken nur
## innerhalb eines Schwarms, Separation dagegen zwischen allen Boids.
## Aufteilen/Vereinen bedeutet schlicht: Boids wechseln den Schwarm.

var id: int = 0
var color: Color = Color.WHITE
var boids: Array[Boid] = []


func add(boid: Boid) -> void:
	if boid.swarm != null and boid.swarm != self:
		boid.swarm.boids.erase(boid)
	boid.swarm = self
	boid.modulate = color
	boids.append(boid)


func size() -> int:
	return boids.size()


func is_empty() -> bool:
	return boids.is_empty()


func centroid() -> Vector2:
	if boids.is_empty():
		return Vector2.ZERO
	var sum := Vector2.ZERO
	for b in boids:
		sum += b.position
	return sum / boids.size()


func average_velocity() -> Vector2:
	if boids.is_empty():
		return Vector2.ZERO
	var sum := Vector2.ZERO
	for b in boids:
		sum += b.velocity
	return sum / boids.size()


## Größter Abstand eines Boids zum Schwerpunkt.
func radius() -> float:
	var c := centroid()
	var r2 := 0.0
	for b in boids:
		r2 = maxf(r2, b.position.distance_squared_to(c))
	return sqrt(r2)
