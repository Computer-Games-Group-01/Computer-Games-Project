class_name FlockSettings
extends Resource
## Alle Stellschrauben des Schwarmverhaltens an einem Ort.
## Als .tres speicherbar – so lassen sich später z. B. "schnelle_boids.tres"
## oder "traege_boids.tres" anlegen und pro Schwarm/Level austauschen.

@export_group("Bewegung")
@export var min_speed: float = 80.0
@export var max_speed: float = 210.0
## Wie schnell ein Boid auf eine Regel reagiert (1/s). Höher = wendiger.
@export var steer_gain: float = 3.0
## Max. Beschleunigung durch die drei Schwarm-Regeln (px/s²).
@export var max_force: float = 600.0
## Max. Beschleunigung durch Felder & Co. (darf größer sein -> Felder "gewinnen").
@export var max_external_force: float = 2200.0

@export_group("Wahrnehmung")
@export var perception_radius: float = 110.0
@export var separation_radius: float = 34.0

@export_group("Gewichte")
@export var separation_weight: float = 1.7
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 0.9

@export_group("Weltgrenzen")
@export var boundary_margin: float = 300.0
@export var boundary_force: float = 700.0

@export_group("Performance")
## 1 = jeder Boid berechnet sein Steering in jedem Frame.
## 2 oder 3 = nur jeder 2./3. Boid pro Frame (reihum) – bei vielen hundert Boids fast
## unsichtbar, spart aber entsprechend viel Rechenzeit.
@export_range(1, 6) var steering_stride: int = 1
