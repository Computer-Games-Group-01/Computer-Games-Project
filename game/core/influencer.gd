class_name Influencer
extends Node2D
## Basisklasse für ALLES, was Boids beeinflusst.
##
## Gravitationsfelder, schwarze Löcher – und später Hindernisse, Gegner,
## Windzonen, Magnete … – erben von dieser Klasse und überschreiben nur
## get_force_on() und get_reach(). Der FlockManager kennt keine konkreten
## Typen, er fragt einfach alle Nodes der Gruppe "influencers".

## Nur diesen Schwarm beeinflussen (null = alle Schwärme).
var target_swarm: Swarm = null
## Zum An-/Ausschalten, z. B. durch Schalter in Rätseln.
var enabled: bool = true


func _ready() -> void:
	add_to_group(&"influencers")


## Beschleunigung (px/s²), die dieser Influencer auf den Boid ausübt.
func get_force_on(_boid: Boid) -> Vector2:
	return Vector2.ZERO


## Maximale Entfernung, in der dieser Influencer wirkt (schnelle Vorab-Prüfung).
func get_reach() -> float:
	return 0.0


func affects(boid: Boid) -> bool:
	return enabled and (target_swarm == null or boid.swarm == target_swarm)


## Welteinheiten pro Bildschirm-Pixel (für zoom-unabhängige Linienbreiten).
func screen_px() -> float:
	return 1.0 / maxf(get_canvas_transform().get_scale().x, 0.001)
