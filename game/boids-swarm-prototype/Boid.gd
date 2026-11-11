extends CharacterBody2D
class_name Boid

@export var max_speed: float = 250.0
@export var min_speed: float = 80.0
@export var max_force: float = 400.0 # Hier ist die gefixte Lenkkraft!
@export var neighbor_radius: float = 40.0 #used to be 100
@export var separation_radius: float = 35.0

var weight_separation: float = 2.0
var weight_alignment: float = 1.0
var weight_cohesion: float = 1.5 #used to be 1.0
var weight_gravity: float = 1.5

var swarm_group: int = 0
var manager: Node2D = null

var acceleration: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not manager:
		return
		
	acceleration = Vector2.ZERO
	
	var neighbors = get_neighbors()
	var sep = compute_separation(neighbors)
	var ali = compute_alignment(neighbors)
	var coh = compute_cohesion(neighbors)
	
	acceleration += sep * weight_separation
	acceleration += ali * weight_alignment
	acceleration += coh * weight_cohesion
	
	var grav = compute_gravity_force()
	acceleration += grav * weight_gravity
	
	velocity += acceleration * delta
	velocity = velocity.limit_length(max_speed)
	
	if velocity.length() < min_speed and velocity.length() > 0:
		velocity = velocity.normalized() * min_speed
		
	move_and_slide()
	
	if velocity.length() > 10.0:
		rotation = velocity.angle()

func get_neighbors() -> Array:
	var neighbors: Array = []
	for boid in manager.boids:
		# Wir entfernen den Gruppen-Check hier, damit JEDER Fisch im Radius erkannt wird
		if boid != self and global_position.distance_to(boid.global_position) < neighbor_radius:
			neighbors.append(boid)
	return neighbors

func compute_separation(neighbors: Array) -> Vector2:
	var steer = Vector2.ZERO
	var count = 0
	for other in neighbors:
		# Separation gilt für ALLE Nachbarn (kein Gruppen-Filter)
		var d = global_position.distance_to(other.global_position)
		if d < separation_radius and d > 0:
			var diff = (global_position - other.global_position).normalized() / d
			steer += diff
			count += 1
	if count > 0:
		steer /= count
		if steer.length() > 0:
			steer = steer.normalized() * max_speed - velocity
			steer = steer.limit_length(max_force)
	return steer

func compute_alignment(neighbors: Array) -> Vector2:
	var sum_vel = Vector2.ZERO
	var count = 0
	for other in neighbors:
		# Alignment gilt NUR für die eigene Gruppe
		if other.swarm_group == self.swarm_group:
			sum_vel += other.velocity
			count += 1
	if count > 0:
		sum_vel /= count
		sum_vel = sum_vel.normalized() * max_speed
		var steer = sum_vel - velocity
		return steer.limit_length(max_force)
	return Vector2.ZERO

func compute_cohesion(neighbors: Array) -> Vector2:
	var sum_pos = Vector2.ZERO
	var count = 0
	for other in neighbors:
		# Cohesion gilt NUR für die eigene Gruppe
		if other.swarm_group == self.swarm_group:
			sum_pos += other.global_position
			count += 1
	if count > 0:
		sum_pos /= count
		return seek(sum_pos)
	return Vector2.ZERO

func seek(target: Vector2) -> Vector2:
	var desired = (target - global_position).normalized() * max_speed
	var steer = desired - velocity
	return steer.limit_length(max_force)

func compute_gravity_force() -> Vector2:
	var targets = manager.get_gravity_points_for_group(swarm_group)
	
	if targets.is_empty():
		var center = get_viewport_rect().size / 2.0
		return seek(center) * 0.3
		
	var total_force = Vector2.ZERO
	for target in targets:
		var to_target = target.global_position - global_position
		var distance = to_target.length()
		
		if distance < 60.0:
			var dir = to_target.normalized()
			var tangent = Vector2(-dir.y, dir.x).normalized() * max_speed
			var steer = (tangent - velocity).limit_length(max_force)
			total_force += steer * 1.5 
		else:
			total_force += seek(target.global_position)
			
	return total_force
