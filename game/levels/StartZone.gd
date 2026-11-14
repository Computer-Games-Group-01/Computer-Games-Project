class_name StartZone
extends Node2D
## Markiert den Startbereich eines Schwarms visuell in der Spielwelt.

@export var radius: float = 180.0
@export var color: Color = Color("4fc3f7")


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(color, 0.08))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(color, 0.45), 3.0, true)
