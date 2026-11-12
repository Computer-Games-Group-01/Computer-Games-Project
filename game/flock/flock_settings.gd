class_name FlockSettings
extends Resource
## Alle Stellschrauben des Schwarmverhaltens an einem Ort.
## Als .tres speicherbar – so lassen sich später z. B. "schnelle_boids.tres"
## oder "traege_boids.tres" anlegen und pro Schwarm/Level austauschen.

@export_group("Bewegung")
@export var min_speed: float = 80.0
@export var max_speed: float = 210.0
## Max. Beschleunigung durch die drei Schwarm-Regeln (px/s²).
@export var max_force: float = 600.0
## Max. Beschleunigung durch Felder & Co. (darf größer sein -> Felder "gewinnen").
@export var max_external_force: float = 2200.0
## Wie schnell sich die DARSTELLUNG zur Flugrichtung dreht (höher = direkter, 0 = sofort).
@export var turn_smoothing: float = 14.0

@export_group("Wahrnehmung")
@export var perception_radius: float = 110.0
@export var separation_radius: float = 34.0

@export_group("Gewichte")
## Abstoßung von zu nahen Boids (wächst weich mit der Nähe).
@export var separation_weight: float = 0.8
## Angleichen der Flugrichtung/-geschwindigkeit an die Schwarm-Nachbarn.
@export var alignment_weight: float = 1.0
## Zug zum Schwerpunkt der Schwarm-Nachbarn (wie eine Feder: im Zentrum = 0).
@export var cohesion_weight: float = 0.35
## Wie stark Alignment reagiert (1/s).
@export var steer_gain: float = 3.0
## Schwache Bindung an den eigenen Schwarm: Boids, die weiter als `swarm_bond_radius`
## vom Schwarm-Schwerpunkt entfernt sind, werden zurückgezogen (Felder überstimmen das leicht).
@export var swarm_bond_weight: float = 0.4
@export var swarm_bond_radius: float = 220.0

@export_group("Weltgrenzen")
@export var boundary_margin: float = 300.0
@export var boundary_force: float = 700.0

@export_group("Performance")
## Schwarm-Regeln auf mehrere CPU-Kerne verteilen (WorkerThreadPool).
@export var use_threads: bool = true
## 1 = jeder Boid berechnet die Regeln in jedem Frame.
## 2 oder 3 = nur jeder 2./3. Boid pro Frame (reihum) – spart entsprechend Rechenzeit.
@export_range(1, 6) var steering_stride: int = 1
