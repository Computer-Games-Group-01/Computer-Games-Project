@tool
class_name BoidZone
extends Node2D
## Base class for everything that affects boids: fields, obstacles, enemies, goals.
##
## The zone registers with the BoidWorld in setup(). The BoidWorld then calls
## get_force_on() every frame for boids within reach, and constrain() as well
## for solid zones. Subclasses override get_force_on() and get_reach().

## Affect only this swarm (null = all swarms).
var target_swarm: Swarm = null
## Switches the zone on and off, e.g. from switches in puzzles.
var enabled: bool = true
## true = the BoidWorld calls constrain() after every move (hard collision).
var solid: bool = false
## The simulation, set by setup(). null = not registered yet.
var boids: BoidWorld = null


func _ready() -> void:
	add_to_group(&"uses_boids")


## Called by World after loading the level, and by the PlayerController for placed fields.
func setup(boid_world: BoidWorld) -> void:
	boids = boid_world
	boid_world.add_zone(self)


func _exit_tree() -> void:
	if boids != null:
		boids.remove_zone(self)
		boids = null


## Beschleunigung (px/s²), die dieser BoidZone auf den Boid ausübt.
func get_force_on(_boid: Boid) -> Vector2:
	return Vector2.ZERO


## Nur für solid-BoidZone: Boid-Position/-Geschwindigkeit nach der Bewegung korrigieren
## (z. B. aus einem Hindernis herausschieben).
func constrain(_boid: Boid) -> void:
	pass


## Maximale Entfernung, in der dieser BoidZone wirkt (schnelle Vorab-Prüfung).
func get_reach() -> float:
	return 0.0


func affects(boid: Boid) -> bool:
	return enabled and (target_swarm == null or boid.swarm == target_swarm)


## Welteinheiten pro Bildschirm-Pixel (für zoom-unabhängige Linienbreiten).
func screen_px() -> float:
	return 1.0 / maxf(get_canvas_transform().get_scale().x, 0.001)
