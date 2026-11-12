class_name Boid
extends Node2D
## Ein einzelner Boid: nur Zustand + Darstellung.
## Die Steuerung berechnet der FlockManager (alle Boids teilen sich dort
## eine Nachbarschaftssuche – das ist viel schneller als pro-Boid-Logik).

signal died(boid: Boid)

@export var size: float = 13.0

var velocity: Vector2 = Vector2.ZERO
## Gesamtbeschleunigung des letzten Frames (nur zur Info/Debug).
var acceleration: Vector2 = Vector2.ZERO
## Anteil aus den Schwarm-Regeln (bleibt bei steering_stride > 1 zwischen den Updates erhalten).
var flock_accel: Vector2 = Vector2.ZERO
var swarm: Swarm = null
var max_speed: float = 210.0
var min_speed: float = 80.0
var alive: bool = true


func _draw() -> void:
	# Weiß zeichnen – die Schwarmfarbe kommt über "modulate".
	draw_colored_polygon(PackedVector2Array([
		Vector2(size, 0.0),
		Vector2(-size * 0.7, -size * 0.55),
		Vector2(-size * 0.35, 0.0),
		Vector2(-size * 0.7, size * 0.55),
	]), Color.WHITE)


## Boid "stirbt" (schwarzes Loch, Gegner, Falle …). Entfernt wird er
## vom FlockManager am Ende des Frames.
func kill() -> void:
	if not alive:
		return
	alive = false
	died.emit(self)
